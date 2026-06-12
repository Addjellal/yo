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
from cv_parser import parse_cv
from tracker import Tracker
from history import SessionStore
from locations import COUNTRIES, COUNTRY_NAMES, FR_REGIONS
from ai import JobMatcher, CoverLetterGenerator
from ai.matcher import parse_exclude_keywords
from ai.cover_letter import TONES
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
)

_PROJECT_DIR = Path(__file__).resolve().parent.parent
_STATIC_DIR = Path(__file__).resolve().parent / "static"

# Jeton de session : généré à chaque démarrage, injecté dans la page servie.
AUTH_TOKEN = secrets.token_urlsafe(32)

_STATIC_FILES = {
    "style.css": "text/css; charset=utf-8",
    "app.js": "application/javascript; charset=utf-8",
}

_MAX_BODY_DEFAULT = 1 * 1024 * 1024        # 1 Mo pour les requêtes JSON
_MAX_BODY_UPLOAD = 36 * 1024 * 1024        # CV 25 Mo → ~34 Mo en base64
_CV_EXTENSIONS = (".pdf", ".docx", ".txt")
_DOWNLOAD_EXTENSIONS = (".txt", ".pdf", ".csv", ".json")
_DOWNLOAD_TYPES = {
    ".txt": "text/plain; charset=utf-8",
    ".pdf": "application/pdf",
    ".csv": "text/csv; charset=utf-8",
    ".json": "application/json; charset=utf-8",
}

_SECTOR_LABELS = dict(SECTORS)
_EXPERIENCE_KEYS = {k for k, _ in EXPERIENCE_LEVELS}
_COUNTRY_CODES = {c for c, _ in COUNTRIES}

# ─── Jobs d'arrière-plan (scan, lettre) ──────────────────────────────────────

class _Job:
    def __init__(self, kind: str):
        self.id = uuid.uuid4().hex
        self.kind = kind                  # "scan" | "letter"
        self.status = "running"           # running | done | error
        self.error = ""
        self.log: list[str] = []
        self.offers: list[JobOffer] = []  # résultats d'un scan
        self.cv_text = ""                 # CV parsé (réutilisé pour les lettres)
        self.query = ""
        self.result: dict = {}            # résultat d'une lettre
        self.created = time.time()
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
_STORE_LOCK = threading.Lock()


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


def _register_job(job: _Job) -> None:
    with _JOBS_LOCK:
        _JOBS[job.id] = job
        # Purge des vieux jobs : garde les 20 plus récents
        if len(_JOBS) > 20:
            for jid in sorted(_JOBS, key=lambda j: _JOBS[j].created)[:-20]:
                if _JOBS[jid].status != "running":
                    del _JOBS[jid]


def _get_job(job_id: str) -> _Job | None:
    with _JOBS_LOCK:
        return _JOBS.get(job_id)


# ─── Sérialisation des offres pour le front ─────────────────────────────────

def _offer_dict(offer: JobOffer, index: int, status: str = "new") -> dict:
    return {
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


def _entry_dict(key: str, entry: dict) -> dict:
    return {
        "key": key,
        "title": str(entry.get("title", ""))[:300],
        "company": str(entry.get("company", ""))[:200],
        "url": str(entry.get("url", ""))[:2000],
        "source": str(entry.get("source", ""))[:60],
        "score": entry.get("score"),
        "updated": str(entry.get("updated", ""))[:19],
        "first_seen": str(entry.get("first_seen", ""))[:19],
    }


# ─── Liste des CV disponibles ────────────────────────────────────────────────

_EXCLUDED_TXT = {"requirements.txt", "robots.txt"}


def _list_cv_files() -> list[str]:
    files = []
    for path in sorted(_PROJECT_DIR.iterdir()):
        if not path.is_file() or path.name.startswith("."):
            continue
        if path.suffix.lower() not in _CV_EXTENSIONS:
            continue
        if path.name.lower() in _EXCLUDED_TXT:
            continue
        files.append(path.name)
    return files


# ─── Exécution d'un scan (thread) ────────────────────────────────────────────

def _run_scan(job: _Job, p: dict) -> None:
    try:
        job.add_log(f"Lecture du CV : {p['cv']}")
        cv_text = parse_cv(str(_PROJECT_DIR / p["cv"]))
        job.cv_text = cv_text
        job.add_log(f"CV parsé ({len(cv_text)} caractères)")

        config.country = p["country"]
        tracker = _get_tracker()

        job.add_log(f"Scraping de {len(p['sources'])} source(s) en parallèle…")
        all_offers: list[JobOffer] = []
        seen_keys: set[str] = set()
        with ThreadPoolExecutor(max_workers=min(len(p["sources"]), 5)) as executor:
            futures = {
                executor.submit(_run_one_scraper, key, p["query"], p["location"], p["max"]): key
                for key in p["sources"]
            }
            for future in as_completed(futures):
                source_name, offers, error = future.result()
                if error:
                    job.add_log(f"⚠ {source_name} : {error}")
                    continue
                fresh = [o for o in offers if o.unique_key() not in seen_keys]
                seen_keys.update(o.unique_key() for o in fresh)
                all_offers.extend(fresh)
                job.add_log(f"✓ {source_name} : {len(fresh)} offres")

        if not p["include_seen"]:
            before = len(all_offers)
            with _TRACKER_LOCK:
                all_offers = tracker.filter_visible(all_offers)
            hidden = before - len(all_offers)
            if hidden:
                job.add_log(f"{hidden} offre(s) déjà traitée(s) filtrée(s)")

        if not all_offers:
            job.add_log("Aucune offre à analyser.")
            job.status = "done"
            return

        job.add_log(f"Analyse IA de {len(all_offers)} offres (score min {p['min_score']}/10)…")
        matcher = JobMatcher(cv_text)
        with _TRACKER_LOCK:
            rejections = tracker.recent_rejections()
        if rejections:
            matcher.set_rejected_examples(rejections)
            job.add_log(f"Préférences : {len(rejections)} rejet(s) pris en compte")

        matched = matcher.score_offers(
            all_offers,
            min_score=p["min_score"],
            sectors=p["sectors"],
            exclude=p["exclude"],
            experience_level=p["experience"],
        )
        with _TRACKER_LOCK:
            tracker.mark_many(matched, "seen")

        job.offers = matched
        job.query = p["query"]
        with _STORE_LOCK:
            _get_store().add_session(
                kind="web", criteria=_session_criteria(p), offers=matched,
                found=len(all_offers),
            )
        job.add_log(f"Terminé : {len(matched)} offre(s) avec un score ≥ {p['min_score']}/10")
        job.status = "done"
    except Exception as e:
        job.error = str(e)[:500]
        job.status = "error"
    finally:
        _SCAN_LOCK.release()


def _session_criteria(p: dict) -> dict:
    """Critères d'un scan web au format de l'historique (secteurs en clés)."""
    label_to_key = {label: key for key, label in SECTORS}
    return {
        "query": p["query"],
        "cv": p["cv"],
        "country": p["country"],
        "location": p["location"],
        "sectors": [label_to_key[s] for s in p["sectors"] if s in label_to_key],
        "experience": p["experience"],
        "sources": p["sources"],
        "min_score": p["min_score"],
        "exclude": p["exclude"],
    }


def _run_rescore(job: _Job, p: dict) -> None:
    """Re-score le CV contre toutes les offres connues, sans scraper."""
    try:
        job.add_log(f"Lecture du CV : {p['cv']}")
        cv_text = parse_cv(str(_PROJECT_DIR / p["cv"]))
        job.cv_text = cv_text

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
        matcher = JobMatcher(cv_text)
        with _TRACKER_LOCK:
            rejections = tracker.recent_rejections()
        if rejections:
            matcher.set_rejected_examples(rejections)

        matched = matcher.score_offers(
            offers,
            min_score=p["min_score"],
            sectors=p["sectors"],
            exclude=p["exclude"],
            experience_level=p["experience"],
            top_k=RESCORE_TOP_K,
            two_stage=True,
        )
        with _TRACKER_LOCK:
            tracker.mark_many(matched, "seen")

        job.offers = matched
        job.query = "(re-scoring de la base)"
        p2 = dict(p, query="(re-scoring de la base)", sources=[])
        with _STORE_LOCK:
            _get_store().add_session(
                kind="rescore", criteria=_session_criteria(p2), offers=matched,
                found=len(offers),
            )
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
        tracker = _get_tracker()
        with _TRACKER_LOCK:
            applied_titles = [
                str(e.get("title", "")) for e in tracker.list_by_status("applied") if e.get("title")
            ]
        generator = CoverLetterGenerator(scan_job.cv_text, applied_history=applied_titles)
        result = generator.generate(offer, tone=tone)
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
            "txt_file": txt_path.name,
            "pdf_file": pdf_name,
        }
        job.status = "done"
    except Exception as e:
        job.error = str(e)[:500]
        job.status = "error"


# ─── Validation des paramètres de scan ───────────────────────────────────────

def _validate_scan_params(body: dict) -> tuple[dict | None, str]:
    query = str(body.get("query", "")).strip()[:200]
    if not query:
        return None, "La recherche est vide."

    cv = str(body.get("cv", "")).strip()
    if cv not in _list_cv_files():
        return None, "CV introuvable : déposez un fichier PDF/DOCX/TXT dans le dossier du projet."

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
    try:
        max_per_source = max(1, min(200, int(body.get("max", config.max_jobs_per_source))))
    except (TypeError, ValueError):
        max_per_source = config.max_jobs_per_source

    exclude = parse_exclude_keywords(config.exclude_keywords) + parse_exclude_keywords(
        str(body.get("exclude", ""))[:1000]
    )

    return {
        "query": query,
        "cv": cv,
        "country": country,
        "location": str(body.get("location", "")).strip()[:120],
        "sources": sources,
        "sectors": sectors,
        "experience": experience,
        "min_score": min_score,
        "max": max_per_source,
        "exclude": exclude,
        "include_seen": bool(body.get("include_seen", False)),
    }, ""


def _validate_rescore_params(body: dict) -> tuple[dict | None, str]:
    """Paramètres du re-scoring : comme un scan, sans requête ni sources."""
    cv = str(body.get("cv", "")).strip()
    if cv not in _list_cv_files():
        return None, "CV introuvable : déposez un fichier PDF/DOCX/TXT dans le dossier du projet."

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
        "cv": cv,
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
    ("AI_PRESCORE_MODEL", False),
    ("AI_MATCH_MODEL", False),
    ("AI_LETTER_MODEL", False),
    ("AI_FALLBACK", False),
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
        host = (self.headers.get("Host") or "").split(":")[0].strip().lower()
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
        except (json.JSONDecodeError, UnicodeDecodeError):
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
        elif path == "/api/download":
            self._api_download(query.get("file", [""])[0])
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
        elif path == "/api/session-load":
            self._api_session_load()
        elif path == "/api/letter":
            self._api_letter()
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
        # via Content-Disposition)
        if (not name or not re.fullmatch(r"[A-Za-z0-9 ._-]{1,120}", name)
                or name.startswith(".")
                or Path(name).suffix.lower() not in _DOWNLOAD_EXTENSIONS):
            self._error("Fichier non autorisé", 403)
            return
        out_dir = Path(config.output_dir).resolve()
        target = (out_dir / name).resolve()
        if target.parent != out_dir or not target.is_file():
            self._error("Fichier introuvable", 404)
            return
        self._send(200, _DOWNLOAD_TYPES[target.suffix.lower()], target.read_bytes(), download_name=name)

    # ── API ──

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
        if job.status == "done" and job.kind == "letter":
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

    def _api_sessions(self):
        with _STORE_LOCK:
            store = _get_store()
            sessions = store.list_sessions()
            letters = store.list_letters()
        for s in sessions:
            s["summary"] = _criteria_summary(s.get("criteria", {}))
        self._json({"sessions": sessions[:100], "letters": letters[:50]})

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
        # CV de la session : reparsé si le fichier existe encore (pour les lettres)
        cv_name = session.get("criteria", {}).get("cv", "")
        if cv_name in _list_cv_files():
            try:
                job.cv_text = parse_cv(str(_PROJECT_DIR / cv_name))
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
            self._error("Scan introuvable — relancez une recherche.", 404)
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
        target = _PROJECT_DIR / f"{stem}{ext}"
        target.write_bytes(data)
        self._json({"ok": True, "name": target.name, "cv_files": _list_cv_files()})

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
