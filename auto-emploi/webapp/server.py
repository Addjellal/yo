"""
Interface web locale — serveur HTTP construit sur la bibliothèque standard
uniquement (aucune dépendance supplémentaire à installer).

Sécurité :
- écoute uniquement sur 127.0.0.1 : jamais accessible depuis le réseau ;
- jeton de session aléatoire exigé sur toutes les routes /api/* — un site
  malveillant ouvert dans le même navigateur ne peut pas piloter l'app
  (anti-CSRF), et l'en-tête Host est vérifié (anti-DNS-rebinding) ;
- fichiers servis uniquement depuis webapp/static/ (liste blanche) et
  output/ (noms sans chemin, extensions autorisées, jamais de dotfiles —
  le .tracker.json et le .env sont inaccessibles) ;
- Content-Security-Policy stricte, corps de requêtes bornés ;
- toutes les écritures .env passent par save_to_env (liste blanche de clés).
"""
import base64
import json
import re
import secrets
import threading
import time
import urllib.parse
import uuid
import webbrowser
from collections import Counter
from concurrent.futures import ThreadPoolExecutor, as_completed
from datetime import datetime
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path

from config import config, save_to_env
from cv_parser import parse_cv, _cache_path
from tracker import Tracker
from history import SessionStore
from cv_store import CVStore, EXCLUDED_FILENAMES, list_cv_files
from locations import COUNTRIES, COUNTRY_NAMES, FR_REGIONS
from ai import CoverLetterGenerator
from ai.matcher import parse_exclude_keywords, score_offers_multi
from ai.cover_letter import TONES, merge_cv_texts, recent_letter_examples
from ai.cv_extract import CVExtractor, derive_search_queries
from integrations import notion_configured, export_to_notion
from job_scrapers.base import JobOffer

# Réutilise la logique CLI : sources, secteurs, niveaux, exports
from main import (
    SOURCE_MAP,
    SECTORS,
    EXPERIENCE_LEVELS,
    RESCORE_TOP_K,
    _run_one_scraper,
    _criteria_summary,
    save_results,
    save_raw_offers,
    save_dropped_offers,
)
from app_utils import get_logger
from output_paths import cv_dir, find_output_file

_LOG = get_logger()

_PROJECT_DIR = Path(__file__).resolve().parent.parent
_STATIC_DIR = Path(__file__).resolve().parent / "static"

# Jeton de session : généré à chaque démarrage, injecté dans la page servie.
AUTH_TOKEN = secrets.token_urlsafe(32)

_STATIC_FILES = {
    "style.css": "text/css; charset=utf-8",
    "app.js": "application/javascript; charset=utf-8",
    "fonts/space-grotesk.woff2": "font/woff2",
}

_MAX_BODY_DEFAULT = 1 * 1024 * 1024        # 1 Mo pour les requêtes JSON
_MAX_BODY_UPLOAD = 36 * 1024 * 1024        # CV 25 Mo → ~34 Mo en base64
_CV_EXTENSIONS = (".pdf", ".docx", ".txt")
# « Sans plafond » : valeur sentinelle bien au-delà des limites de pagination
# internes de chaque scraper (MAX_PAGES, MAX_START…), qui bornent le réel.
_UNLIMITED_MAX = 10_000
_DOWNLOAD_EXTENSIONS = (".txt", ".pdf", ".csv", ".json", ".jsonl")
_DOWNLOAD_TYPES = {
    ".txt": "text/plain; charset=utf-8",
    ".pdf": "application/pdf",
    ".csv": "text/csv; charset=utf-8",
    ".json": "application/json; charset=utf-8",
    ".jsonl": "application/json; charset=utf-8",
}

_SECTOR_LABELS = dict(SECTORS)
_EXPERIENCE_KEYS = {k for k, _ in EXPERIENCE_LEVELS}
_COUNTRY_CODES = {c for c, _ in COUNTRIES}

# ─── Jobs d'arrière-plan (scan, lettre) ──────────────────────────────────────

class _Job:
    def __init__(self, kind: str):
        self.id = uuid.uuid4().hex
        self.kind = kind                  # "scan" | "letter" | "cv"
        self.status = "running"           # running | done | error
        self.error = ""
        self.log: list[str] = []
        self.offers: list[JobOffer] = []  # résultats d'un scan
        self.cv_text = ""                 # CV fusionné (réutilisé pour les lettres)
        self.cv_texts: dict[str, str] = {}  # {label → texte} (matching multi-CV)
        self.query = ""
        self.result: dict = {}            # résultat d'une lettre / d'une analyse CV
        self.created = time.time()
        self.stop_event = threading.Event()  # bouton « Stopper » (scan/rescore)
        self._lock = threading.Lock()

    def add_log(self, message: str) -> None:
        with self._lock:
            self.log.append(message)

    def snapshot_log(self) -> list[str]:
        with self._lock:
            return list(self.log)


_JOBS: dict[str, _Job] = {}
_JOBS_LOCK = threading.Lock()
_SCAN_LOCK = threading.Lock()      # un seul scan à la fois
_TRACKER_LOCK = threading.Lock()   # sérialise les écritures du tracker

_tracker: Tracker | None = None
_store: SessionStore | None = None
_cv_store: CVStore | None = None
_STORE_LOCK = threading.Lock()
_CV_LOCK = threading.Lock()        # sérialise les accès au registre des CV


def _get_tracker() -> Tracker:
    global _tracker
    if _tracker is None:
        _tracker = Tracker(Path(config.output_dir) / ".tracker.json")
    return _tracker


def _get_store() -> SessionStore:
    global _store
    if _store is None:
        _store = SessionStore(Path(config.output_dir) / ".sessions.json")
    return _store


def _get_cv_store() -> CVStore:
    global _cv_store
    if _cv_store is None:
        _cv_store = CVStore(Path(config.output_dir) / ".cvs.json")
    return _cv_store


# Plafonds de rétention par type de job. Les jobs « scan » portent les offres
# que la page Résultats référence pour les lettres, le suivi et l'export : ils
# doivent survivre aux jobs lettre/CV qui s'accumulent. (Bug historique : une
# purge globale à 20 jobs supprimait le scan courant après quelques recherches
# → « Scan introuvable » sur toute génération de lettre.)
_JOB_RETENTION = {"scan": 6, "letter": 20, "cv": 20, "check": 6}


def _register_job(job: _Job) -> None:
    with _JOBS_LOCK:
        _JOBS[job.id] = job
        _LOG.info("job %s créé (%s)", job.id[:8], job.kind)
        # Purge par type : les vieux jobs du même type, jamais ceux d'un autre
        keep = _JOB_RETENTION.get(job.kind, 20)
        same_kind = sorted(
            (j for j in _JOBS.values() if j.kind == job.kind),
            key=lambda j: j.created,
        )
        for old in same_kind[:-keep]:
            if old.status != "running":
                del _JOBS[old.id]


def _get_job(job_id: str) -> _Job | None:
    with _JOBS_LOCK:
        return _JOBS.get(job_id)


# ─── Sérialisation des offres pour le front ─────────────────────────────────

def _offer_dict(offer: JobOffer, index: int, status: str = "new") -> dict:
    d = {
        "index": index,
        "title": offer.title,
        "company": offer.company,
        "location": offer.location,
        "description": (offer.description or "")[:1500],
        "url": offer.url,
        "source": offer.source,
        "salary": offer.salary,
        "contract": offer.contract_type,
        "score": offer.match_score,
        "reasons": offer.match_reasons or "",
        "strengths": offer.match_strengths or "",
        "gaps": offer.match_gaps or "",
        "status": status,
    }
    if offer.best_cv and isinstance(offer.cv_scores, dict) and offer.cv_scores:
        d["best_cv"] = offer.best_cv
        d["cv_scores"] = [
            {"cv": label, "score": r.get("score", 0), "reasons": r.get("reasons", ""),
             "strengths": r.get("strengths", ""), "gaps": r.get("gaps", "")}
            for label, r in sorted(offer.cv_scores.items(),
                                   key=lambda kv: -kv[1].get("score", 0))
            if isinstance(r, dict)
        ]
    return d


def _entry_dict(key: str, entry: dict) -> dict:
    return {
        "key": key,
        "title": str(entry.get("title", ""))[:300],
        "company": str(entry.get("company", ""))[:200],
        "url": str(entry.get("url", ""))[:2000],
        "source": str(entry.get("source", ""))[:60],
        "score": entry.get("score"),
        "updated": str(entry.get("updated", ""))[:19],
    }


# ─── Liste des CV disponibles + registre ─────────────────────────────────────
# Les nouveaux imports vont dans output/cv/ ; les CV historiques restés à la
# racine du projet restent visibles et utilisables (résolution dans les deux).

def _list_cv_files() -> list[str]:
    names = list_cv_files(cv_dir())
    seen = set(names)
    names += [n for n in list_cv_files(_PROJECT_DIR) if n not in seen]
    return names


def _cv_path(name: str) -> Path:
    """Chemin réel d'un CV par nom nu : output/cv/ d'abord, puis la racine du
    projet (anciens imports). Retourne le chemin output/cv même inexistant."""
    name = Path(name).name
    candidate = cv_dir() / name
    if candidate.is_file():
        return candidate
    legacy = _PROJECT_DIR / name
    return legacy if legacy.is_file() else candidate


def _cv_payload(entry: dict) -> dict:
    """Entrée du registre sérialisée pour le front : profil effectif fusionné
    (manuel > IA) + provenance par section."""
    profile, sources = CVStore.effective_profile(entry)
    return {
        "id": entry.get("id", ""),
        "filename": entry.get("filename", ""),
        "label": entry.get("label", ""),
        "added": entry.get("added", ""),
        "analyzed": entry.get("analyzed", ""),
        "file_exists": _cv_path(entry.get("filename", "")).is_file(),
        "profile": profile,
        "sources": sources,
        "overrides": entry.get("overrides") or {},
        "extracted": entry.get("profile") or {},
    }


def _cvs_payload() -> list[dict]:
    """CV actifs, registre synchronisé avec les fichiers du dossier projet."""
    with _CV_LOCK:
        store = _get_cv_store()
        store.sync(_list_cv_files())
        return [_cv_payload(e) for e in store.list_cvs()]


def _load_cv_texts(names: list[str]) -> dict[str, str]:
    """Parse chaque CV et retourne {label → texte effectif} (corrections
    manuelles incluses)."""
    texts: dict[str, str] = {}
    for name in names:
        raw = parse_cv(str(_cv_path(name)))
        with _CV_LOCK:
            entry = _get_cv_store().register(name)
            label = entry.get("label") or name
            if label in texts:
                label = name
            texts[label] = _get_cv_store().effective_text(entry, raw)
    return texts


def _cv_history_display(criteria_cv: str) -> str:
    """Libellé du/des CV d'une session : « CV supprimé : x » si disparu."""
    names = [Path(n.strip()).name for n in str(criteria_cv or "").split(",") if n.strip()]
    if not names:
        return ""
    with _CV_LOCK:
        store = _get_cv_store()
        return " + ".join(
            store.history_label(n, _cv_path(n).is_file()) for n in names
        )


def _style_examples() -> dict[str, list[str]] | None:
    """Exemples few-shot depuis les lettres passées, si LETTER_EXAMPLES=on."""
    if config.letter_examples != "on":
        return None
    with _STORE_LOCK:
        examples = recent_letter_examples(_get_store())
    return examples if any(examples.values()) else None


# ─── Exécution d'un scan (thread) ────────────────────────────────────────────

def _run_scan(job: _Job, p: dict) -> None:
    try:
        _LOG.info("scan %s : début (query=%r, sources=%s, no_ai=%s)",
                  job.id[:8], p.get("query", ""), ",".join(p["sources"]), p.get("no_ai"))
        if p["cvs"]:
            job.add_log(f"Lecture du/des CV : {', '.join(p['cvs'])}")
            job.cv_texts = _load_cv_texts(p["cvs"])
            job.cv_text = merge_cv_texts(job.cv_texts)
            job.add_log(f"{len(job.cv_texts)} CV parsé(s) ({len(job.cv_text)} caractères)")
        else:  # mode test scraper sans CV
            job.add_log("Mode test scraper : aucun CV nécessaire.")

        if p.get("global"):
            job.add_log("Recherche globale : génération des requêtes depuis vos CV…")
            queries = derive_search_queries(job.cv_text)
            p["query"] = " · ".join(queries)
            job.add_log(f"Requêtes générées : {p['query']}")
        else:
            queries = [p["query"]]

        config.country = p["country"]
        tracker = _get_tracker()

        if p["max"] >= _UNLIMITED_MAX:
            job.add_log(f"Scraping de {len(p['sources'])} source(s) en parallèle (sans plafond)…")
        else:
            job.add_log(f"Scraping de {len(p['sources'])} source(s) en parallèle…")
        all_offers: list[JobOffer] = []
        seen_keys: set[str] = set()
        executor = ThreadPoolExecutor(max_workers=min(len(p["sources"]), 5))
        try:
            futures = {
                executor.submit(_run_one_scraper, key, query, p["location"], p["max"]):
                    (key, query)
                for key in p["sources"] for query in queries
            }
            counts: dict[str, int] = {}
            for future in as_completed(futures):
                if job.stop_event.is_set():
                    job.add_log("⏹ Arrêt demandé — scraping interrompu.")
                    break
                source_name, offers, error = future.result()
                if error:
                    job.add_log(f"⚠ {source_name} : {error}")
                    continue
                fresh = [o for o in offers if o.unique_key() not in seen_keys]
                seen_keys.update(o.unique_key() for o in fresh)
                all_offers.extend(fresh)
                counts[source_name] = counts.get(source_name, 0) + len(fresh)
                job.add_log(f"✓ {source_name} : {counts[source_name]} offres")
        finally:
            # Sur arrêt : ne pas attendre les scrapers en cours, annuler les
            # lots en file. Sinon, attente normale de la fin des threads.
            stopped = job.stop_event.is_set()
            executor.shutdown(wait=not stopped, cancel_futures=stopped)

        # Trace brute : toutes les offres collectées, avant tout filtrage
        if all_offers:
            raw_path = save_raw_offers(all_offers, p["query"])
            job.add_log(f"Offres brutes sauvegardées : {raw_path.name}")

        if not p["include_seen"]:
            before_filter = list(all_offers)
            with _TRACKER_LOCK:
                all_offers = tracker.filter_visible(all_offers)
            hidden = len(before_filter) - len(all_offers)
            if hidden:
                job.add_log(f"{hidden} offre(s) déjà traitée(s) filtrée(s)")
                visible_keys = {o.unique_key() for o in all_offers}
                save_dropped_offers(
                    [o for o in before_filter if o.unique_key() not in visible_keys],
                    p["query"], "déjà traitée (favori/postulée/rejetée)",
                )

        if not all_offers:
            job.add_log("Aucune offre à analyser.")
            job.status = "done"
            return

        # Mode test scraper : prévisualisation brute, AUCUN appel IA — pour
        # ajuster requête/filtres avant de connecter le pipeline IA
        if p.get("no_ai"):
            job.offers = all_offers
            job.query = p["query"]
            job.add_log(
                f"🔌 Mode test scraper : {len(all_offers)} offre(s) brute(s), aucune analyse IA. "
                "Ajustez vos filtres puis relancez sans ce mode."
            )
            job.status = "done"
            _LOG.info("scan %s : terminé en mode test (%d offres brutes)", job.id[:8], len(all_offers))
            return

        multi = f" × {len(job.cv_texts)} CV" if len(job.cv_texts) > 1 else ""
        job.add_log(f"Analyse IA de {len(all_offers)} offres{multi} (score min {p['min_score']}/10)…")
        with _TRACKER_LOCK:
            rejections = tracker.recent_rejections()
        if rejections:
            job.add_log(f"Préférences : {len(rejections)} rejet(s) pris en compte")

        matched = score_offers_multi(
            job.cv_texts,
            all_offers,
            min_score=p["min_score"],
            sectors=p["sectors"],
            exclude=p["exclude"],
            experience_level=p["experience"],
            rejected_examples=rejections,
            shared_prefilter=True,
            should_stop=job.stop_event.is_set,
            progress=job.add_log,
        )
        with _TRACKER_LOCK:
            tracker.mark_many(matched, "seen")

        # Traçabilité : offres analysées mais sous le score minimum / exclues
        matched_keys = {o.unique_key() for o in matched}
        save_dropped_offers(
            [o for o in all_offers if o.unique_key() not in matched_keys],
            p["query"], f"score < {p['min_score']}/10 ou exclue par filtre",
        )

        job.offers = matched
        job.query = p["query"]
        # Session enregistrée sauf arrêt sans aucun résultat (rien à garder)
        if matched or not job.stop_event.is_set():
            with _STORE_LOCK:
                _get_store().add_session(
                    kind="web", criteria=_session_criteria(p), offers=matched,
                    found=len(all_offers),
                )
        if job.stop_event.is_set():
            job.add_log(f"⏹ Recherche stoppée : {len(matched)} offre(s) déjà scorées conservées.")
        else:
            job.add_log(f"Terminé : {len(matched)} offre(s) avec un score ≥ {p['min_score']}/10")
        job.status = "done"
        _LOG.info("scan %s : terminé (%d offres retenues / %d collectées)",
                  job.id[:8], len(matched), len(all_offers))
    except Exception as e:
        _LOG.exception("scan %s : échec", job.id[:8])
        job.error = str(e)[:500]
        job.status = "error"
    finally:
        _SCAN_LOCK.release()


def _session_criteria(p: dict) -> dict:
    """Critères d'un scan web au format de l'historique (secteurs en clés)."""
    label_to_key = {label: key for key, label in SECTORS}
    return {
        "query": p["query"],
        "global": bool(p.get("global")),
        "cv": ",".join(p["cvs"]),
        "country": p["country"],
        "location": p["location"],
        "sectors": [label_to_key[s] for s in p["sectors"] if s in label_to_key],
        "experience": p["experience"],
        "sources": p["sources"],
        "min_score": p["min_score"],
        "exclude": p["exclude"],
    }


def _run_rescore(job: _Job, p: dict) -> None:
    """Re-score le(s) CV contre toutes les offres connues, sans scraper."""
    try:
        job.add_log(f"Lecture du/des CV : {', '.join(p['cvs'])}")
        job.cv_texts = _load_cv_texts(p["cvs"])
        job.cv_text = merge_cv_texts(job.cv_texts)

        with _STORE_LOCK:
            offers = _get_store().all_offers()
        job.add_log(f"{len(offers)} offre(s) connue(s) dans l'historique")
        tracker = _get_tracker()
        if not p["include_seen"]:
            with _TRACKER_LOCK:
                offers = tracker.filter_visible(offers)
        if not offers:
            job.add_log("Aucune offre à re-scorer (historique vide ou tout déjà traité).")
            job.status = "done"
            return

        job.add_log(f"Re-scoring de {len(offers)} offre(s) — pré-filtre code pur "
                    f"(top {RESCORE_TOP_K}) puis pré-scoring IA…")
        with _TRACKER_LOCK:
            rejections = tracker.recent_rejections()

        matched = score_offers_multi(
            job.cv_texts,
            offers,
            min_score=p["min_score"],
            sectors=p["sectors"],
            exclude=p["exclude"],
            experience_level=p["experience"],
            rejected_examples=rejections,
            top_k=RESCORE_TOP_K,
            two_stage=True,
            should_stop=job.stop_event.is_set,
            progress=job.add_log,
        )
        with _TRACKER_LOCK:
            tracker.mark_many(matched, "seen")

        job.offers = matched
        job.query = "(re-scoring de la base)"
        p2 = dict(p, query="(re-scoring de la base)", sources=[])
        if matched or not job.stop_event.is_set():
            with _STORE_LOCK:
                _get_store().add_session(
                    kind="rescore", criteria=_session_criteria(p2), offers=matched,
                    found=len(offers),
                )
        if job.stop_event.is_set():
            job.add_log(f"⏹ Re-scoring stoppé : {len(matched)} offre(s) déjà scorées conservées.")
        else:
            job.add_log(f"Terminé : {len(matched)} offre(s) avec un score ≥ {p['min_score']}/10")
        job.status = "done"
    except Exception as e:
        job.error = str(e)[:500]
        job.status = "error"
    finally:
        _SCAN_LOCK.release()


def _run_letter(job: _Job, scan_job: _Job, index: int, tone: str) -> None:
    try:
        offer = scan_job.offers[index]
        _LOG.info("lettre %s : début (offre « %s » @ %s, ton %s)",
                  job.id[:8], offer.title[:60], offer.company[:40], tone)
        tracker = _get_tracker()
        with _TRACKER_LOCK:
            applied_titles = [
                str(e.get("title", "")) for e in tracker.list_by_status("applied") if e.get("title")
            ]
        # Lettre fondée sur le SEUL CV le mieux corresp. à l'offre (best_cv,
        # déjà départagé par score puis ordre des CV dans le matching) — évite
        # de surcharger le prompt avec les autres CV. Repli : texte fusionné.
        cv_text = scan_job.cv_text
        if offer.best_cv and scan_job.cv_texts.get(offer.best_cv):
            cv_text = scan_job.cv_texts[offer.best_cv]
            _LOG.info("lettre %s : CV retenu « %s » (meilleure correspondance)",
                      job.id[:8], offer.best_cv)
        generator = CoverLetterGenerator(
            cv_text,
            applied_history=applied_titles,
            style_examples=_style_examples(),
        )
        _LOG.info("lettre %s : appel LLM…", job.id[:8])
        result = generator.generate(offer, tone=tone)
        _LOG.info("lettre %s : LLM ok (%d caractères) — écriture fichiers",
                  job.id[:8], len(result.get("letter", "")))
        txt_path, pdf_path = generator.save(offer, result)
        pdf_name = pdf_path.name if pdf_path.exists() else ""
        with _TRACKER_LOCK:
            tracker.mark(offer, "applied")
        with _STORE_LOCK:
            _get_store().add_letter(
                offer, tone, result.get("language", "fr"), txt_path.name, pdf_name,
            )
        job.result = {
            "letter": result["letter"],
            "email_subject": result["email_subject"],
            "email_body": result["email_body"],
            "language": result.get("language", "fr"),
            "review_notes": result.get("review_notes") or [],
            "txt_file": txt_path.name,
            "pdf_file": pdf_name,
        }
        job.status = "done"
        _LOG.info("lettre %s : terminée (%s)", job.id[:8], txt_path.name)
    except Exception as e:
        _LOG.exception("lettre %s : échec", job.id[:8])
        job.error = str(e)[:500]
        job.status = "error"


# Vérification de disponibilité : requête HTTP légère par offre, AUCUN appel IA.
# 200–3xx = en ligne ; 404/410 = retirée ; échec réseau/timeout = indéterminé.
_CHECK_HEADERS = {
    "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 "
                  "(KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36",
    "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
}


def _check_one(url: str) -> dict:
    """État d'une URL d'offre : available True/False/None (indéterminé)."""
    import requests
    if not url or not url.startswith(("http://", "https://")):
        return {"available": None, "status": 0}
    try:
        # HEAD d'abord (léger) ; certains sites refusent HEAD → repli GET.
        resp = requests.head(url, timeout=8, allow_redirects=True, headers=_CHECK_HEADERS)
        if resp.status_code in (403, 405) or resp.status_code >= 500:
            resp = requests.get(url, timeout=8, allow_redirects=True,
                                headers=_CHECK_HEADERS, stream=True)
        code = resp.status_code
        if code in (404, 410):
            available = False                 # retirée
        elif 200 <= code < 400:
            available = True                  # en ligne
        else:
            available = None                  # 403/500… : indéterminé
        return {"available": available, "status": code}
    except requests.RequestException:
        return {"available": None, "status": 0}


def _run_check(job: _Job, scan_job: _Job) -> None:
    """Reparcourt les offres et teste leur disponibilité sur les plateformes,
    sans aucun appel IA (simple requête HTTP par offre, en parallèle)."""
    try:
        offers = list(scan_job.offers)
        job.add_log(f"Vérification de la disponibilité de {len(offers)} offre(s) (sans IA)…")
        results: dict[int, dict] = {}
        done = 0
        with ThreadPoolExecutor(max_workers=8) as pool:
            futures = {pool.submit(_check_one, o.url): i for i, o in enumerate(offers)}
            for fut in as_completed(futures):
                if job.stop_event.is_set():
                    job.add_log("⏹ Vérification interrompue.")
                    break
                i = futures[fut]
                results[i] = fut.result()
                done += 1
                if done % 10 == 0 or done == len(offers):
                    job.add_log(f"  ↳ {done}/{len(offers)} vérifiées")
        online = sum(1 for r in results.values() if r["available"] is True)
        gone = sum(1 for r in results.values() if r["available"] is False)
        unknown = len(results) - online - gone
        job.result = {
            "results": [{"index": i, **r} for i, r in sorted(results.items())],
        }
        job.add_log(f"Terminé : {online} en ligne · {gone} retirée(s) · {unknown} indéterminée(s).")
        job.status = "done"
    except Exception as e:
        _LOG.exception("check %s : échec", job.id[:8])
        job.error = str(e)[:500]
        job.status = "error"


def _run_cv_analyze(job: _Job, cv_id: str) -> None:
    """Extraction IA du profil structuré d'un CV (page « Mes CV »)."""
    try:
        with _CV_LOCK:
            entry = _get_cv_store().get(cv_id)
        if entry is None:
            raise ValueError("CV introuvable dans le registre")
        filename = entry.get("filename", "")
        job.add_log(f"Lecture de {filename}…")
        raw = parse_cv(str(_cv_path(filename)))
        job.add_log(f"CV parsé ({len(raw)} caractères) — extraction IA en cours…")
        profile = CVExtractor().extract(raw)
        with _CV_LOCK:
            store = _get_cv_store()
            store.set_profile(entry["id"], profile)
            fresh = store.get(entry["id"])
        job.result = {"cv": _cv_payload(fresh)} if fresh else {}
        job.add_log("Profil extrait.")
        job.status = "done"
    except Exception as e:
        job.error = str(e)[:500]
        job.status = "error"


# ─── Validation des paramètres de scan ───────────────────────────────────────

def _validate_cvs(body: dict) -> list[str]:
    """Liste `cvs` (cases à cocher) : seuls les fichiers réellement présents
    sont retenus, 5 maximum."""
    raw = body.get("cvs")
    names = [str(c).strip() for c in raw if isinstance(c, str)] if isinstance(raw, list) else []
    files = set(_list_cv_files())
    return [n for n in names if n in files][:5]


def _validate_scan_params(body: dict) -> tuple[dict | None, str]:
    is_global = bool(body.get("global"))
    no_ai = bool(body.get("no_ai", False))
    if no_ai and is_global:
        # La recherche globale génère ses requêtes par IA : incompatible avec
        # le mode test sans IA — une requête explicite est exigée.
        return None, "Mode test scraper : saisissez une requête (la recherche globale utilise l'IA)."
    query = str(body.get("query", "")).strip()[:200]
    if not query and not is_global:
        return None, "La recherche est vide."

    cvs = _validate_cvs(body)
    if not cvs and not no_ai:
        return None, "CV introuvable : importez un fichier PDF/DOCX/TXT ou cochez au moins un CV."

    country = str(body.get("country", "fr")).strip().lower()
    if country not in _COUNTRY_CODES:
        country = "fr"

    raw_sources = body.get("sources") or []
    sources = [s for s in raw_sources if isinstance(s, str) and s in SOURCE_MAP][:10]
    if not sources:
        return None, "Aucune source sélectionnée."

    raw_sectors = body.get("sectors") or []
    sectors = [_SECTOR_LABELS[s] for s in raw_sectors if isinstance(s, str) and s in _SECTOR_LABELS]

    experience = str(body.get("experience", "")).strip()
    if experience not in _EXPERIENCE_KEYS:
        experience = ""

    try:
        min_score = max(0, min(10, int(body.get("min_score", config.min_match_score))))
    except (TypeError, ValueError):
        min_score = config.min_match_score
    # max vide ou 0 = sans plafond (les scrapers gardent leurs propres limites
    # de pagination) — pensé pour les LLM locaux où le volume ne coûte rien
    try:
        max_per_source = int(body.get("max", config.max_jobs_per_source))
    except (TypeError, ValueError):
        max_per_source = config.max_jobs_per_source
    max_per_source = _UNLIMITED_MAX if max_per_source <= 0 else min(max_per_source, _UNLIMITED_MAX)

    exclude = parse_exclude_keywords(config.exclude_keywords) + parse_exclude_keywords(
        str(body.get("exclude", ""))[:1000]
    )

    return {
        "query": query,
        "global": is_global,
        "cvs": cvs,
        "country": country,
        "location": str(body.get("location", "")).strip()[:120],
        "sources": sources,
        "sectors": sectors,
        "experience": experience,
        "min_score": min_score,
        "max": max_per_source,
        "exclude": exclude,
        "include_seen": bool(body.get("include_seen", False)),
        # Mode test scraper : collecte sans aucun appel IA (offres brutes)
        "no_ai": no_ai,
    }, ""


def _validate_rescore_params(body: dict) -> tuple[dict | None, str]:
    """Paramètres du re-scoring : comme un scan, sans requête ni sources."""
    cvs = _validate_cvs(body)
    if not cvs:
        return None, "CV introuvable : importez un fichier PDF/DOCX/TXT ou cochez au moins un CV."

    raw_sectors = body.get("sectors") or []
    sectors = [_SECTOR_LABELS[s] for s in raw_sectors if isinstance(s, str) and s in _SECTOR_LABELS]
    experience = str(body.get("experience", "")).strip()
    if experience not in _EXPERIENCE_KEYS:
        experience = ""
    try:
        min_score = max(0, min(10, int(body.get("min_score", config.min_match_score))))
    except (TypeError, ValueError):
        min_score = config.min_match_score
    exclude = parse_exclude_keywords(config.exclude_keywords) + parse_exclude_keywords(
        str(body.get("exclude", ""))[:1000]
    )
    return {
        "query": "",
        "cvs": cvs,
        "country": config.country,
        "location": "",
        "sources": [],
        "sectors": sectors,
        "experience": experience,
        "min_score": min_score,
        "exclude": exclude,
        "include_seen": bool(body.get("include_seen", False)),
    }, ""


# ─── Réglages exposés dans l'interface ───────────────────────────────────────

# (clé .env, secret ?) — seules ces clés sont lisibles/modifiables depuis le web
_SETTINGS_KEYS: list[tuple[str, bool]] = [
    ("PROVIDER", False),
    ("ANTHROPIC_API_KEY", True),
    ("ANTHROPIC_MODEL", False),
    ("OLLAMA_BASE_URL", False),
    ("OLLAMA_MODEL", False),
    ("ADZUNA_APP_ID", False),
    ("ADZUNA_APP_KEY", True),
    ("FRANCE_TRAVAIL_CLIENT_ID", False),
    ("FRANCE_TRAVAIL_CLIENT_SECRET", True),
    ("NOTION_TOKEN", True),
    ("NOTION_DATABASE_ID", False),
    ("EXCLUDE_KEYWORDS", False),
    ("CANDIDATE_NAME", False),
    ("CANDIDATE_EMAIL", False),
    ("CANDIDATE_PHONE", False),
    ("CANDIDATE_CITY", False),
    ("AI_PRESCORE_BACKEND", False),
    ("AI_MATCH_BACKEND", False),
    ("AI_LETTER_BACKEND", False),
    ("AI_REVIEW_BACKEND", False),
    ("AI_PRESCORE_MODEL", False),
    ("AI_MATCH_MODEL", False),
    ("AI_LETTER_MODEL", False),
    ("AI_REVIEW_MODEL", False),
    ("AI_FALLBACK", False),
    ("LETTER_EXAMPLES", False),
    ("LETTER_REVIEW", False),
    ("MULTI_CV_SHARED_KEEP", False),
    ("DEFAULT_SOURCES", False),
    ("DEFAULT_SECTORS", False),
    ("DEFAULT_LOCATION", False),
    ("DEFAULT_COUNTRY", False),
    ("DEFAULT_EXPERIENCE", False),
]


def _masked_settings() -> dict:
    out = {}
    for key, secret in _SETTINGS_KEYS:
        value = str(getattr(config, key.lower(), "") or "")
        if not value:
            out[key] = {"set": False, "display": ""}
        elif secret:
            out[key] = {"set": True, "display": "••••" + value[-4:] if len(value) > 8 else "••••"}
        else:
            out[key] = {"set": True, "display": value[:120]}
    return out


# ─── Statistiques ────────────────────────────────────────────────────────────

def _weekly_applied(entries: list[dict], weeks: int = 12) -> list[dict]:
    """Candidatures par semaine ISO sur les N dernières semaines."""
    counts: Counter[str] = Counter()
    for e in entries:
        raw = str(e.get("updated", ""))[:10]
        try:
            d = datetime.strptime(raw, "%Y-%m-%d")
        except ValueError:
            continue
        year, week, _ = d.isocalendar()
        counts[f"{year}-S{week:02d}"] += 1
    labels = sorted(counts)[-weeks:]
    return [{"week": w, "count": counts[w]} for w in labels]


def _stats_payload() -> dict:
    tracker = _get_tracker()
    with _TRACKER_LOCK:
        counts = tracker.stats()
        followups = [_entry_dict(k, e) for k, e in tracker.followup_entries(days=14)]
        applied = [_entry_dict(k, e) for k, e in tracker.entries_by_status("applied")]
        favorites = [_entry_dict(k, e) for k, e in tracker.entries_by_status("favorite")]
        rejected = [_entry_dict(k, e) for k, e in tracker.entries_by_status("rejected")]
    applied.sort(key=lambda e: e["updated"], reverse=True)
    favorites.sort(key=lambda e: e["updated"], reverse=True)
    rejected.sort(key=lambda e: e["updated"], reverse=True)

    by_source: Counter[str] = Counter(e["source"] or "?" for e in applied)
    return {
        "counts": counts,
        "followups": followups,
        "applied": applied[:50],
        "favorites": favorites[:50],
        "rejected": rejected[:30],
        "by_source": [{"source": s, "count": c} for s, c in by_source.most_common(8)],
        "weekly": _weekly_applied(applied),
    }


# ─── Handler HTTP ────────────────────────────────────────────────────────────

class _Handler(BaseHTTPRequestHandler):
    server_version = "AutoEmploi/1.0"
    protocol_version = "HTTP/1.1"

    # ── Helpers ──

    def log_message(self, fmt, *args):  # journal minimal, sans bruit
        pass

    def _host_ok(self) -> bool:
        host = (self.headers.get("Host") or "").strip().lower()
        if host.startswith("["):  # IPv6 : [::1] ou [::1]:8765
            host = host.split("]")[0] + "]"
        else:
            host = host.split(":")[0]
        return host in ("127.0.0.1", "localhost", "[::1]")

    def _auth_ok(self) -> bool:
        token = self.headers.get("X-Auth-Token") or ""
        return secrets.compare_digest(token, AUTH_TOKEN)

    def _send(self, status: int, content_type: str, body: bytes,
              download_name: str = "", close: bool = False) -> None:
        self.send_response(status)
        self.send_header("Content-Type", content_type)
        self.send_header("Content-Length", str(len(body)))
        self.send_header("X-Content-Type-Options", "nosniff")
        self.send_header("Referrer-Policy", "no-referrer")
        self.send_header("Cache-Control", "no-store")
        self.send_header(
            "Content-Security-Policy",
            "default-src 'self'; style-src 'self' 'unsafe-inline'; img-src 'self' data:; "
            "connect-src 'self'; frame-ancestors 'none'; base-uri 'none'; form-action 'none'",
        )
        if download_name:
            self.send_header("Content-Disposition", f'attachment; filename="{download_name}"')
        if close:
            # Erreur avant lecture du corps : fermer évite qu'un corps non lu
            # soit interprété comme la requête suivante sur la connexion keep-alive.
            self.send_header("Connection", "close")
            self.close_connection = True
        self.end_headers()
        self.wfile.write(body)

    def _json(self, obj: dict, status: int = 200) -> None:
        self._send(status, "application/json; charset=utf-8", json.dumps(obj, ensure_ascii=False).encode("utf-8"))

    def _error(self, message: str, status: int = 400) -> None:
        body = json.dumps({"error": message}, ensure_ascii=False).encode("utf-8")
        self._send(status, "application/json; charset=utf-8", body, close=True)

    def _read_body(self, limit: int = _MAX_BODY_DEFAULT) -> dict | None:
        try:
            length = int(self.headers.get("Content-Length") or 0)
        except ValueError:
            return None
        if length <= 0 or length > limit:
            return None
        try:
            data = json.loads(self.rfile.read(length).decode("utf-8"))
        except (ValueError, UnicodeDecodeError, RecursionError):
            # ValueError couvre JSONDecodeError ; RecursionError protège d'un
            # JSON volontairement très imbriqué ([[[…]]]) tenant dans la limite.
            return None
        return data if isinstance(data, dict) else None

    # ── Routage ──

    def do_GET(self):
        if not self._host_ok():
            self._error("Hôte non autorisé", 403)
            return
        parsed = urllib.parse.urlparse(self.path)
        path = parsed.path

        if path == "/" or path == "/index.html":
            self._serve_index()
            return
        if path.startswith("/static/"):
            self._serve_static(path[len("/static/"):])
            return

        if not path.startswith("/api/"):
            self._error("Introuvable", 404)
            return
        if not self._auth_ok():
            self._error("Jeton de session invalide — rechargez la page.", 401)
            return

        query = urllib.parse.parse_qs(parsed.query)
        if path == "/api/state":
            self._api_state()
        elif path == "/api/job":
            self._api_job(query.get("id", [""])[0])
        elif path == "/api/stats":
            self._json(_stats_payload())
        elif path == "/api/sessions":
            self._api_sessions()
        elif path == "/api/cvs":
            self._json({"cvs": _cvs_payload()})
        elif path == "/api/download":
            self._api_download(query.get("file", [""])[0])
        elif path == "/api/local-models":
            self._api_local_models()
        else:
            self._error("Route inconnue", 404)

    def do_POST(self):
        if not self._host_ok():
            self._error("Hôte non autorisé", 403)
            return
        path = urllib.parse.urlparse(self.path).path
        if not path.startswith("/api/") or not self._auth_ok():
            self._error("Jeton de session invalide — rechargez la page.", 401)
            return

        if path == "/api/scan":
            self._api_scan()
        elif path == "/api/rescore":
            self._api_rescore()
        elif path == "/api/stop":
            self._api_stop()
        elif path == "/api/session-load":
            self._api_session_load()
        elif path == "/api/letter":
            self._api_letter()
        elif path == "/api/check-availability":
            self._api_check_availability()
        elif path == "/api/letter-save":
            self._api_letter_save()
        elif path == "/api/track":
            self._api_track()
        elif path == "/api/track-key":
            self._api_track_key()
        elif path == "/api/settings":
            self._api_settings()
        elif path == "/api/cv":
            self._api_cv_upload()
        elif path == "/api/cv-analyze":
            self._api_cv_analyze()
        elif path == "/api/cv-update":
            self._api_cv_update()
        elif path == "/api/cv-delete":
            self._api_cv_delete()
        elif path == "/api/export":
            self._api_export()
        elif path == "/api/notion":
            self._api_notion()
        else:
            self._error("Route inconnue", 404)

    # ── Pages et fichiers ──

    def _serve_index(self):
        try:
            html = (_STATIC_DIR / "index.html").read_text(encoding="utf-8")
        except OSError:
            self._error("index.html manquant", 500)
            return
        html = html.replace("__AUTH_TOKEN__", AUTH_TOKEN)
        self._send(200, "text/html; charset=utf-8", html.encode("utf-8"))

    def _serve_static(self, name: str):
        content_type = _STATIC_FILES.get(name)
        if content_type is None:
            self._error("Introuvable", 404)
            return
        try:
            body = (_STATIC_DIR / name).read_bytes()
        except OSError:
            self._error("Introuvable", 404)
            return
        self._send(200, content_type, body)

    def _api_download(self, name: str):
        # Nom nu uniquement : caractères sûrs, pas de dotfile, extension sûre.
        # (le jeu de caractères restreint empêche aussi toute injection d'en-tête
        # via Content-Disposition). Le serveur résout le nom dans les
        # sous-dossiers connus de output/ — jamais de chemin fourni par le client.
        if (not name or not re.fullmatch(r"[A-Za-z0-9 ._-]{1,120}", name)
                or name.startswith(".")
                or Path(name).suffix.lower() not in _DOWNLOAD_EXTENSIONS):
            self._error("Fichier non autorisé", 403)
            return
        target = find_output_file(name)
        if target is None:
            self._error("Fichier introuvable", 404)
            return
        self._send(200, _DOWNLOAD_TYPES[target.suffix.lower()], target.read_bytes(), download_name=name)

    # ── API ──

    def _api_local_models(self):
        """Détection des serveurs LLM locaux (Ollama, LM Studio, llama.cpp) +
        RAM/VRAM + suggestions de modèles — sondes localhost uniquement."""
        from integrations import scan_local_models
        try:
            self._json(scan_local_models())
        except Exception as e:
            _LOG.exception("scan modèles locaux : échec")
            self._error(f"Détection impossible : {str(e)[:200]}", 500)

    def _api_state(self):
        provider_ready = (
            bool(config.anthropic_api_key) if config.provider == "anthropic" else True
        )
        sources = []
        for key, (label, _) in SOURCE_MAP.items():
            if key == "adzuna":
                configured, auth = bool(config.adzuna_app_id and config.adzuna_app_key), True
            elif key == "ft":
                configured, auth = bool(config.france_travail_client_id and config.france_travail_client_secret), True
            else:
                configured, auth = True, False
            sources.append({"key": key, "label": label, "auth": auth, "configured": configured})
        self._json({
            "provider": config.provider,
            "provider_ready": provider_ready,
            "model": config.anthropic_model if config.provider == "anthropic" else config.ollama_model,
            "countries": [{"code": c, "name": n} for c, n in COUNTRIES],
            "regions": FR_REGIONS,
            "sectors": [{"key": k, "label": v} for k, v in SECTORS],
            "experience_levels": [{"key": k, "label": v} for k, v in EXPERIENCE_LEVELS],
            "tones": [{"key": k, "label": v} for k, v in TONES.items()],
            "sources": sources,
            "cv_files": _list_cv_files(),
            "cvs": [
                {"id": c["id"], "filename": c["filename"], "label": c["label"],
                 "analyzed": bool(c["analyzed"])}
                for c in _cvs_payload()
            ],
            "notion": notion_configured(),
            "min_score": config.min_match_score,
            "max_per_source": config.max_jobs_per_source,
            "settings": _masked_settings(),
            "defaults": {
                "sources": [s for s in config.default_sources.split(",") if s.strip()],
                "sectors": [s for s in config.default_sectors.split(",") if s.strip()],
                "location": config.default_location,
                "country": config.default_country if config.default_country in COUNTRY_NAMES else "fr",
                "experience": config.default_experience if config.default_experience in _EXPERIENCE_KEYS else "",
            },
        })

    def _api_scan(self):
        body = self._read_body()
        if body is None:
            self._error("Requête invalide")
            return
        params, err = _validate_scan_params(body)
        if params is None:
            self._error(err)
            return
        if not _SCAN_LOCK.acquire(blocking=False):
            self._error("Un scan est déjà en cours — attendez qu'il se termine.", 409)
            return
        job = _Job("scan")
        _register_job(job)
        threading.Thread(target=_run_scan, args=(job, params), daemon=True).start()
        self._json({"job_id": job.id})

    def _api_job(self, job_id: str):
        job = _get_job(job_id)
        if job is None:
            self._error("Job inconnu", 404)
            return
        payload: dict = {"status": job.status, "log": job.snapshot_log(), "kind": job.kind}
        if job.status == "error":
            payload["error"] = job.error
        if job.status == "done" and job.kind == "scan":
            tracker = _get_tracker()
            with _TRACKER_LOCK:
                payload["offers"] = [
                    _offer_dict(o, i, tracker.status_of(o)) for i, o in enumerate(job.offers)
                ]
        if job.status == "done" and job.kind in ("letter", "cv", "check"):
            payload["result"] = job.result
        self._json(payload)

    def _api_rescore(self):
        body = self._read_body()
        if body is None:
            self._error("Requête invalide")
            return
        params, err = _validate_rescore_params(body)
        if params is None:
            self._error(err)
            return
        if not _SCAN_LOCK.acquire(blocking=False):
            self._error("Un scan est déjà en cours — attendez qu'il se termine.", 409)
            return
        job = _Job("scan")
        _register_job(job)
        threading.Thread(target=_run_rescore, args=(job, params), daemon=True).start()
        self._json({"job_id": job.id})

    def _api_stop(self):
        """Arrêt propre d'un scan/re-scoring : les offres déjà scorées sont
        conservées, le reste est abandonné."""
        body = self._read_body()
        if body is None:
            self._error("Requête invalide")
            return
        job = _get_job(str(body.get("job_id", "")))
        if job is None or job.kind != "scan":
            self._error("Recherche introuvable", 404)
            return
        if job.status != "running":
            self._json({"ok": True, "already_done": True})
            return
        job.stop_event.set()
        job.add_log("⏹ Arrêt demandé — fin du lot en cours puis bilan…")
        self._json({"ok": True})

    def _api_sessions(self):
        with _STORE_LOCK:
            store = _get_store()
            sessions = store.list_sessions()
            letters = store.list_letters()
        for s in sessions:
            s["summary"] = _criteria_summary(s.get("criteria", {}))
            s["cv_display"] = _cv_history_display(s.get("criteria", {}).get("cv", ""))
        self._json({"sessions": sessions[:100], "letters": letters[:100]})

    def _api_session_load(self):
        """Recharge une session passée comme un job terminé : le suivi, les
        lettres et l'export fonctionnent dessus comme sur un scan frais."""
        body = self._read_body()
        if body is None:
            self._error("Requête invalide")
            return
        with _STORE_LOCK:
            store = _get_store()
            session = store.get_session(str(body.get("id", ""))[:60])
            offers = store.session_offers(session) if session else []
        if session is None:
            self._error("Session introuvable", 404)
            return
        job = _Job("scan")
        job.offers = offers
        job.query = session.get("criteria", {}).get("query", "")
        # CV de la session : reparsés si les fichiers existent encore (lettres)
        criteria_cv = session.get("criteria", {}).get("cv", "")
        names = [n.strip() for n in criteria_cv.split(",") if n.strip()]
        available = [n for n in names if n in _list_cv_files()]
        if available:
            try:
                job.cv_texts = _load_cv_texts(available)
                job.cv_text = merge_cv_texts(job.cv_texts)
            except (FileNotFoundError, ValueError):
                pass
        job.status = "done"
        _register_job(job)
        tracker = _get_tracker()
        with _TRACKER_LOCK:
            payload_offers = [
                _offer_dict(o, i, tracker.status_of(o)) for i, o in enumerate(offers)
            ]
        self._json({
            "job_id": job.id,
            "offers": payload_offers,
            "query": job.query,
            "letters_available": bool(job.cv_text),
            "date": session.get("date", ""),
        })

    def _api_letter(self):
        body = self._read_body()
        if body is None:
            self._error("Requête invalide")
            return
        scan_job = _get_job(str(body.get("job_id", "")))
        if scan_job is None or scan_job.kind != "scan" or scan_job.status != "done":
            _LOG.warning("lettre refusée : scan job %s introuvable ou non terminé "
                         "(%d jobs en mémoire)", str(body.get("job_id", ""))[:8], len(_JOBS))
            self._error(
                "Session de scan introuvable — rechargez une session depuis "
                "l'onglet Historique ou relancez une recherche.", 404,
            )
            return
        if not scan_job.cv_text:
            self._error("CV de cette session introuvable — relancez une recherche avec un CV.", 400)
            return
        try:
            index = int(body.get("index", -1))
        except (TypeError, ValueError):
            index = -1
        if not (0 <= index < len(scan_job.offers)):
            self._error("Offre inconnue", 404)
            return
        tone = str(body.get("tone", "standard"))
        if tone not in TONES:
            tone = "standard"
        job = _Job("letter")
        _register_job(job)
        threading.Thread(target=_run_letter, args=(job, scan_job, index, tone), daemon=True).start()
        self._json({"job_id": job.id})

    def _api_check_availability(self):
        body = self._read_body()
        if body is None:
            self._error("Requête invalide")
            return
        scan_job = _get_job(str(body.get("job_id", "")))
        if scan_job is None or scan_job.kind != "scan" or scan_job.status != "done":
            self._error("Session de scan introuvable — relancez une recherche.", 404)
            return
        if not scan_job.offers:
            self._error("Aucune offre à vérifier.", 400)
            return
        job = _Job("check")
        _register_job(job)
        threading.Thread(target=_run_check, args=(job, scan_job), daemon=True).start()
        self._json({"job_id": job.id})

    def _api_letter_save(self):
        """Réécrit les fichiers (txt + PDF) d'une lettre éditée dans le
        navigateur — aucun appel IA."""
        body = self._read_body()
        if body is None:
            self._error("Requête invalide")
            return
        scan_job = _get_job(str(body.get("job_id", "")))
        if scan_job is None or scan_job.kind != "scan":
            self._error("Session introuvable", 404)
            return
        try:
            index = int(body.get("index", -1))
        except (TypeError, ValueError):
            index = -1
        if not (0 <= index < len(scan_job.offers)):
            self._error("Offre inconnue", 404)
            return
        letter = str(body.get("letter", "")).strip()[:20000]
        if not letter:
            self._error("Lettre vide")
            return
        result = {
            "letter": letter,
            "email_subject": str(body.get("email_subject", "")).strip()[:200],
            "email_body": str(body.get("email_body", "")).strip()[:2000],
        }
        # save() n'utilise pas le CV ni le LLM : instance minimale suffisante
        generator = CoverLetterGenerator(scan_job.cv_text or "")
        txt_path, pdf_path = generator.save(scan_job.offers[index], result)
        self._json({
            "ok": True,
            "txt_file": txt_path.name,
            "pdf_file": pdf_path.name if pdf_path.exists() else "",
        })

    def _api_track(self):
        body = self._read_body()
        if body is None:
            self._error("Requête invalide")
            return
        scan_job = _get_job(str(body.get("job_id", "")))
        if scan_job is None or scan_job.kind != "scan":
            self._error("Scan introuvable", 404)
            return
        status = str(body.get("status", ""))
        raw = body.get("indices") or []
        indices = [i for i in raw if isinstance(i, int) and 0 <= i < len(scan_job.offers)][:500]
        if not indices:
            self._error("Aucune offre valide")
            return
        try:
            with _TRACKER_LOCK:
                _get_tracker().mark_many([scan_job.offers[i] for i in indices], status)
        except ValueError as e:
            self._error(str(e))
            return
        self._json({"ok": True, "count": len(indices)})

    def _api_track_key(self):
        body = self._read_body()
        if body is None:
            self._error("Requête invalide")
            return
        key = str(body.get("key", ""))[:600]
        status = str(body.get("status", ""))
        try:
            with _TRACKER_LOCK:
                if status == "forget":  # retirée du suivi : retraitée aux prochains scans
                    found = _get_tracker().forget_key(key)
                else:
                    found = _get_tracker().mark_key(key, status)
        except ValueError as e:
            self._error(str(e))
            return
        if not found:
            self._error("Entrée introuvable", 404)
            return
        self._json({"ok": True})

    def _api_settings(self):
        body = self._read_body()
        if body is None:
            self._error("Requête invalide")
            return
        allowed = {k for k, _ in _SETTINGS_KEYS}
        saved = []
        for key, value in body.items():
            if key not in allowed or not isinstance(value, str):
                continue
            value = value.strip()
            if not value:
                continue  # champ laissé vide = inchangé
            try:
                save_to_env(key, value)
                saved.append(key)
            except ValueError:
                continue
        self._json({"ok": True, "saved": saved, "settings": _masked_settings()})

    def _api_cv_upload(self):
        body = self._read_body(limit=_MAX_BODY_UPLOAD)
        if body is None:
            self._error("Requête invalide ou fichier trop volumineux (max 25 Mo)")
            return
        raw_name = str(body.get("filename", ""))
        ext = Path(raw_name).suffix.lower()
        if ext not in _CV_EXTENSIONS:
            self._error("Format non supporté : utilisez PDF, DOCX ou TXT.")
            return
        try:
            data = base64.b64decode(str(body.get("data", "")), validate=True)
        except (ValueError, TypeError):
            self._error("Contenu illisible")
            return
        if not data or len(data) > 25 * 1024 * 1024:
            self._error("Fichier vide ou trop volumineux (max 25 Mo)")
            return
        # Nom strictement assaini, préfixé : aucune traversée de chemin possible
        stem = re.sub(r"[^A-Za-z0-9_-]", "_", Path(raw_name).stem)[:50] or "cv"
        target = cv_dir() / f"{stem}{ext}"
        if target.name.lower() in EXCLUDED_FILENAMES:
            self._error("Ce nom de fichier est réservé — renommez votre CV.")
            return
        target.write_bytes(data)
        with _CV_LOCK:
            entry = _get_cv_store().register(target.name)
        # Analyse IA lancée dès l'import : le profil structuré apparaît dans
        # « Mes CV » sans action manuelle (ré-analyse possible à tout moment)
        analyze_job = _Job("cv")
        _register_job(analyze_job)
        threading.Thread(target=_run_cv_analyze, args=(analyze_job, entry["id"]), daemon=True).start()
        self._json({
            "ok": True, "name": target.name, "cv_files": _list_cv_files(),
            "cv_id": entry.get("id", ""), "label": entry.get("label", ""),
            "analyze_job_id": analyze_job.id,
        })

    def _api_cv_analyze(self):
        """Lance l'extraction IA du profil structuré d'un CV (asynchrone)."""
        body = self._read_body()
        if body is None:
            self._error("Requête invalide")
            return
        cv_id = str(body.get("id", ""))[:40]
        with _CV_LOCK:
            entry = _get_cv_store().get(cv_id)
        if entry is None:
            self._error("CV introuvable", 404)
            return
        if not _cv_path(entry.get("filename", "")).is_file():
            self._error("Le fichier de ce CV n'existe plus.", 404)
            return
        job = _Job("cv")
        _register_job(job)
        threading.Thread(target=_run_cv_analyze, args=(job, entry["id"]), daemon=True).start()
        self._json({"job_id": job.id})

    def _api_cv_update(self):
        """Enregistre le label et/ou les corrections manuelles d'un CV.
        Les sections envoyées remplacent les overrides existants : une section
        absente revient à l'extraction IA."""
        body = self._read_body()
        if body is None:
            self._error("Requête invalide")
            return
        cv_id = str(body.get("id", ""))[:40]
        with _CV_LOCK:
            store = _get_cv_store()
            entry = store.get(cv_id)
            if entry is None:
                self._error("CV introuvable", 404)
                return
            label = body.get("label")
            if isinstance(label, str) and label.strip():
                store.set_label(entry["id"], label)
            overrides = body.get("overrides")
            if isinstance(overrides, dict):
                store.set_overrides(entry["id"], overrides)
            fresh = store.get(entry["id"])
        self._json({"ok": True, "cv": _cv_payload(fresh)})

    def _api_cv_delete(self):
        """Suppression définitive : fichier + cache effacés, tombstone dans le
        registre — l'historique affichera « CV supprimé : x »."""
        body = self._read_body()
        if body is None:
            self._error("Requête invalide")
            return
        cv_id = str(body.get("id", ""))[:40]
        with _CV_LOCK:
            store = _get_cv_store()
            entry = store.get(cv_id)
            if entry is None or entry.get("deleted"):
                self._error("CV introuvable", 404)
                return
            # Fichier effacé AVANT le tombstone : si l'effacement échoue, le
            # sync suivant ré-enregistrerait le fichier restant comme un CV
            # actif neuf et la « suppression » serait silencieusement annulée.
            target = _cv_path(Path(entry.get("filename", "")).name).resolve()
            if target.parent in (_PROJECT_DIR, cv_dir().resolve()) and target.is_file():
                try:
                    target.unlink()
                except OSError:
                    self._error("Impossible d'effacer le fichier — suppression annulée.", 500)
                    return
                cache = _cache_path(target)
                if cache.is_file():
                    try:
                        cache.unlink()
                    except OSError:
                        pass
            store.mark_deleted(entry["id"])
        self._json({
            "ok": True,
            "label": entry.get("label", ""),
            "cvs": _cvs_payload(),
            "cv_files": _list_cv_files(),
        })

    def _api_export(self):
        body = self._read_body()
        if body is None:
            self._error("Requête invalide")
            return
        scan_job = _get_job(str(body.get("job_id", "")))
        if scan_job is None or scan_job.kind != "scan" or not scan_job.offers:
            self._error("Aucun résultat à exporter", 404)
            return
        json_path, csv_path = save_results(scan_job.offers, scan_job.query or "recherche")
        self._json({"ok": True, "json_file": json_path.name, "csv_file": csv_path.name})

    def _api_notion(self):
        body = self._read_body()
        if body is None:
            self._error("Requête invalide")
            return
        if not notion_configured():
            self._error("Notion non configuré (NOTION_TOKEN + NOTION_DATABASE_ID)")
            return
        scan_job = _get_job(str(body.get("job_id", "")))
        if scan_job is None or scan_job.kind != "scan" or not scan_job.offers:
            self._error("Aucun résultat à exporter", 404)
            return
        count = export_to_notion(scan_job.offers)
        self._json({"ok": True, "count": count})


# ─── Démarrage ───────────────────────────────────────────────────────────────

def run(port: int = 8765, open_browser: bool = True) -> None:
    server = ThreadingHTTPServer(("127.0.0.1", port), _Handler)
    url = f"http://127.0.0.1:{port}/"
    print(f"\n  Auto Emploi — interface web : {url}")
    print("  (accessible uniquement depuis cet ordinateur — Ctrl+C pour arrêter)\n")
    if open_browser:
        threading.Timer(0.8, lambda: webbrowser.open(url)).start()
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print("\n  Serveur arrêté.")
    finally:
        server.server_close()
