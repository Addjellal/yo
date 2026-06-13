"""
Historique des sessions de recherche et des lettres générées.

Une session = un scan (CLI --scan/--watch, web, ou re-scoring) : date, critères
utilisés et offres retenues avec leurs scores du moment. Les descriptions sont
conservées (bornées) pour permettre le re-scoring sans relancer les scrapers.

Stockage : OUTPUT_DIR/.sessions.json — même style que le tracker (JSON unique,
écriture atomique, fichier corrompu mis de côté plutôt qu'écrasé).
Schéma :
    {
        "sessions": [
            {
                "id": "20260611-184530-a1b2",
                "date": "2026-06-11T18:45:30",
                "kind": "scan" | "watch" | "web" | "rescore",
                "criteria": {"query": ..., "cv": ..., "country": ...,
                             "location": ..., "sectors": [...],
                             "experience": ..., "sources": [...],
                             "min_score": ..., "exclude": [...]},
                "found": 124,          # offres collectées avant matching
                "offers": [{... champs JobOffer + score/raisons ...}]
            },
            ...
        ],
        "letters": [
            {"date": ..., "offer_key": ..., "title": ..., "company": ...,
             "tone": ..., "language": ..., "txt_file": ..., "pdf_file": ...}
        ]
    }
"""
import json
import os
import secrets
import tempfile
from datetime import datetime
from pathlib import Path

from job_scrapers.base import JobOffer

_MAX_SESSIONS = 200
_MAX_LETTERS = 500
_MAX_OFFERS_PER_SESSION = 400
_MAX_STORE_BYTES = 50 * 1024 * 1024
_DESC_LIMIT = 4000  # assez pour le matching (to_text tronque à 3000)

_OFFER_FIELDS = (
    "id", "title", "company", "location", "url", "apply_url",
    "source", "salary", "contract_type",
)


def _offer_to_dict(offer: JobOffer) -> dict:
    d = {f: getattr(offer, f) for f in _OFFER_FIELDS}
    d["description"] = (offer.description or "")[:_DESC_LIMIT]
    d["score"] = offer.match_score
    d["reasons"] = offer.match_reasons or ""
    d["strengths"] = offer.match_strengths or ""
    d["gaps"] = offer.match_gaps or ""
    if offer.best_cv:
        d["best_cv"] = str(offer.best_cv)[:80]
    if isinstance(offer.cv_scores, dict) and offer.cv_scores:
        d["cv_scores"] = {
            str(label)[:80]: {
                "score": max(0, min(10, int(r.get("score", 0)))) if isinstance(r.get("score"), int) else 0,
                "reasons": str(r.get("reasons", ""))[:400],
                "strengths": str(r.get("strengths", ""))[:600],
                "gaps": str(r.get("gaps", ""))[:400],
            }
            for label, r in list(offer.cv_scores.items())[:6]
            if isinstance(r, dict)
        }
    return d


def _offer_from_dict(d: dict) -> JobOffer | None:
    if not isinstance(d, dict):
        return None
    try:
        offer = JobOffer(
            id=str(d.get("id", "")),
            title=str(d.get("title", "")),
            company=str(d.get("company", "")),
            location=str(d.get("location", "")),
            description=str(d.get("description", "")),
            url=str(d.get("url", "")),
            apply_url=str(d.get("apply_url", "")) or None,
            source=str(d.get("source", "")),
            salary=str(d.get("salary") or "") or None,
            contract_type=str(d.get("contract_type") or "") or None,
        )
    except Exception:
        return None
    if not offer.title:
        return None
    score = d.get("score")
    offer.match_score = max(0, min(10, int(score))) if isinstance(score, int) else None
    offer.match_reasons = str(d.get("reasons", ""))[:400] or None
    offer.match_strengths = str(d.get("strengths", ""))[:600] or None
    offer.match_gaps = str(d.get("gaps", ""))[:400] or None
    offer.best_cv = str(d.get("best_cv", ""))[:80] or None
    raw_scores = d.get("cv_scores")
    if isinstance(raw_scores, dict) and raw_scores:
        offer.cv_scores = {
            str(label)[:80]: {
                "score": max(0, min(10, int(r.get("score", 0)))) if isinstance(r.get("score"), int) else 0,
                "reasons": str(r.get("reasons", ""))[:400],
                "strengths": str(r.get("strengths", ""))[:600],
                "gaps": str(r.get("gaps", ""))[:400],
            }
            for label, r in list(raw_scores.items())[:6]
            if isinstance(r, dict)
        }
    return offer


class SessionStore:
    def __init__(self, store_path: Path):
        self.path = store_path
        self.path.parent.mkdir(parents=True, exist_ok=True)
        self._data: dict = self._load()

    def _load(self) -> dict:
        empty = {"sessions": [], "letters": []}
        if not self.path.exists():
            return empty
        try:
            if self.path.stat().st_size > _MAX_STORE_BYTES:
                raise ValueError("fichier anormalement volumineux")
            data = json.loads(self.path.read_text(encoding="utf-8"))
            if (not isinstance(data, dict)
                    or not isinstance(data.get("sessions"), list)
                    or not isinstance(data.get("letters"), list)):
                raise ValueError("structure inattendue")
            return data
        except (json.JSONDecodeError, OSError, ValueError):
            try:
                self.path.replace(self.path.with_suffix(".json.corrupt"))
            except OSError:
                pass
            return empty

    def _save(self) -> None:
        payload = json.dumps(self._data, ensure_ascii=False)
        fd, tmp_name = tempfile.mkstemp(
            dir=str(self.path.parent), prefix=".sessions_", suffix=".tmp"
        )
        try:
            with os.fdopen(fd, "w", encoding="utf-8") as f:
                f.write(payload)
            os.replace(tmp_name, self.path)
        except OSError:
            try:
                os.unlink(tmp_name)
            except OSError:
                pass
            raise

    # ─── Sessions ────────────────────────────────────────────────────────────

    def add_session(self, kind: str, criteria: dict, offers: list[JobOffer],
                    found: int | None = None) -> str:
        now = datetime.now()
        session_id = now.strftime("%Y%m%d-%H%M%S") + "-" + secrets.token_hex(2)
        self._data["sessions"].append({
            "id": session_id,
            "date": now.isoformat(timespec="seconds"),
            "kind": str(kind)[:20],
            "criteria": _clean_criteria(criteria),
            "found": int(found) if found is not None else len(offers),
            "offers": [_offer_to_dict(o) for o in offers[:_MAX_OFFERS_PER_SESSION]],
        })
        # Plafond : les sessions les plus anciennes sont éliminées
        if len(self._data["sessions"]) > _MAX_SESSIONS:
            self._data["sessions"] = self._data["sessions"][-_MAX_SESSIONS:]
        self._save()
        return session_id

    def list_sessions(self) -> list[dict]:
        """Résumés, du plus récent au plus ancien (sans les offres)."""
        out = []
        for s in reversed(self._data["sessions"]):
            out.append({
                "id": s.get("id", ""),
                "date": s.get("date", ""),
                "kind": s.get("kind", ""),
                "criteria": s.get("criteria", {}),
                "found": s.get("found", 0),
                "kept": len(s.get("offers", [])),
            })
        return out

    def get_session(self, session_id: str) -> dict | None:
        for s in self._data["sessions"]:
            if s.get("id") == session_id:
                return s
        return None

    def session_offers(self, session: dict) -> list[JobOffer]:
        offers = (_offer_from_dict(d) for d in session.get("offers", []))
        return [o for o in offers if o is not None]

    def all_offers(self) -> list[JobOffer]:
        """Toutes les offres connues, dédupliquées (la version la plus récente
        de chaque offre gagne) — pour le re-scoring sans nouvelle recherche."""
        seen: set[str] = set()
        result: list[JobOffer] = []
        for session in reversed(self._data["sessions"]):
            for d in session.get("offers", []):
                offer = _offer_from_dict(d)
                if offer is None:
                    continue
                key = offer.unique_key()
                if key in seen:
                    continue
                seen.add(key)
                result.append(offer)
        return result

    # ─── Lettres ─────────────────────────────────────────────────────────────

    def add_letter(self, offer: JobOffer, tone: str, language: str,
                   txt_file: str, pdf_file: str = "", doc_type: str = "lettre") -> None:
        self._data["letters"].append({
            "date": datetime.now().isoformat(timespec="seconds"),
            "offer_key": offer.unique_key(),
            "title": offer.title,
            "company": offer.company,
            "tone": str(tone)[:20],
            "language": str(language)[:5],
            "doc_type": str(doc_type)[:20],
            "txt_file": str(txt_file)[:200],
            "pdf_file": str(pdf_file)[:200],
        })
        if len(self._data["letters"]) > _MAX_LETTERS:
            self._data["letters"] = self._data["letters"][-_MAX_LETTERS:]
        self._save()

    def list_letters(self) -> list[dict]:
        return list(reversed(self._data["letters"]))


def _clean_criteria(criteria: dict) -> dict:
    """Critères bornés et typés — seules les clés connues sont stockées."""
    c = criteria or {}
    return {
        "query": str(c.get("query", ""))[:200],
        "cv": str(c.get("cv", ""))[:200],
        "country": str(c.get("country", "fr"))[:2],
        "location": str(c.get("location", ""))[:120],
        "sectors": [str(s)[:100] for s in (c.get("sectors") or [])][:20],
        "experience": str(c.get("experience", ""))[:20],
        "sources": [str(s)[:20] for s in (c.get("sources") or [])][:10],
        "min_score": int(c.get("min_score", 6)) if isinstance(c.get("min_score"), int) else 6,
        "exclude": [str(e)[:60] for e in (c.get("exclude") or [])][:50],
        "global": bool(c.get("global")),
    }
