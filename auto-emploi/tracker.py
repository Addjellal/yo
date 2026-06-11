"""
Persistent tracking of job offer states across sessions.

States:
    new       — never seen before (default for unknown offers)
    seen      — auto-marked as soon as displayed in results
    favorite  — user marked with `f N` in browse mode
    applied   — user marked with `a N` (or sent a cover letter)
    rejected  — user marked with `r N` (hidden from future searches)

Storage: a single JSON file in OUTPUT_DIR/.tracker.json
Schema:
    {
        "offers": {
            "<unique_key>": {
                "id":      "indeed_xyz",
                "title":   "...",
                "company": "...",
                "url":     "...",
                "source":  "Indeed",
                "status":  "favorite",
                "score":   8,
                "first_seen": "2026-05-10T10:23:00",
                "updated":     "2026-05-10T11:45:00"
            },
            ...
        }
    }
"""
import json
import os
import tempfile
from datetime import datetime, timedelta
from pathlib import Path
from typing import Iterable

from job_scrapers.base import JobOffer


VALID_STATUSES = ("new", "seen", "favorite", "applied", "rejected")
HIDDEN_STATUSES = ("applied", "rejected")  # hidden from future searches by default

_MAX_TRACKER_BYTES = 50 * 1024 * 1024  # un historique > 50 Mo est forcément corrompu


class Tracker:
    def __init__(self, store_path: Path):
        self.path = store_path
        self.path.parent.mkdir(parents=True, exist_ok=True)
        self._data: dict = self._load()

    def _load(self) -> dict:
        if not self.path.exists():
            return {"offers": {}}
        try:
            if self.path.stat().st_size > _MAX_TRACKER_BYTES:
                raise ValueError("fichier anormalement volumineux")
            data = json.loads(self.path.read_text(encoding="utf-8"))
            if not isinstance(data, dict) or not isinstance(data.get("offers"), dict):
                raise ValueError("structure inattendue")
            return data
        except (json.JSONDecodeError, OSError, ValueError):
            # Fichier corrompu : on le met de côté plutôt que d'écraser l'historique
            try:
                backup = self.path.with_suffix(".json.corrupt")
                self.path.replace(backup)
            except OSError:
                pass
            return {"offers": {}}

    def _save(self) -> None:
        """Écriture atomique : fichier temporaire puis rename — un crash ou un
        Ctrl+C en pleine écriture ne peut pas corrompre l'historique."""
        payload = json.dumps(self._data, ensure_ascii=False, indent=2)
        fd, tmp_name = tempfile.mkstemp(
            dir=str(self.path.parent), prefix=".tracker_", suffix=".tmp"
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

    # ─── Lecture ──────────────────────────────────────────────────────────────

    def status_of(self, offer: JobOffer) -> str:
        entry = self._data["offers"].get(offer.unique_key())
        if entry is None:
            # Compatibilité : l'historique d'avant le changement de clé
            # (titre|entreprise sans lieu) reste reconnu.
            entry = self._data["offers"].get(offer.legacy_key())
        return entry.get("status", "new") if entry else "new"

    def is_hidden(self, offer: JobOffer) -> bool:
        return self.status_of(offer) in HIDDEN_STATUSES

    def filter_visible(self, offers: Iterable[JobOffer]) -> list[JobOffer]:
        """Drop offers marked as applied or rejected."""
        return [o for o in offers if not self.is_hidden(o)]

    def filter_unseen(self, offers: Iterable[JobOffer]) -> list[JobOffer]:
        """Ne garde que les offres jamais vues (mode --watch)."""
        return [o for o in offers if self.status_of(o) == "new"]

    def recent_rejections(self, limit: int = 30) -> list[str]:
        """Titres des dernières offres rejetées — sert à l'apprentissage des
        préférences par le matcher."""
        rejected = [
            e for e in self._data["offers"].values()
            if e.get("status") == "rejected" and e.get("title")
        ]
        rejected.sort(key=lambda e: e.get("updated", ""), reverse=True)
        return [f"{e['title']} — {e.get('company', '')}" for e in rejected[:limit]]

    def needing_followup(self, days: int = 14) -> list[dict]:
        """Candidatures envoyées il y a plus de `days` jours : à relancer."""
        cutoff = (datetime.now() - timedelta(days=days)).isoformat(timespec="seconds")
        return sorted(
            [
                e for e in self._data["offers"].values()
                if e.get("status") == "applied" and e.get("updated", "") < cutoff
            ],
            key=lambda e: e.get("updated", ""),
        )

    def stats(self) -> dict[str, int]:
        counts = {s: 0 for s in VALID_STATUSES}
        for entry in self._data["offers"].values():
            counts[entry.get("status", "seen")] = counts.get(entry.get("status", "seen"), 0) + 1
        counts["total"] = len(self._data["offers"])
        return counts

    # ─── Écriture ─────────────────────────────────────────────────────────────

    def mark(self, offer: JobOffer, status: str) -> None:
        if status not in VALID_STATUSES:
            raise ValueError(f"Statut invalide : {status}")
        key = offer.unique_key()
        now = datetime.now().isoformat(timespec="seconds")
        existing = self._data["offers"].get(key, {})
        self._data["offers"][key] = {
            "id": offer.id,
            "title": offer.title,
            "company": offer.company,
            "url": offer.url,
            "source": offer.source,
            "status": status,
            "score": offer.match_score if offer.match_score is not None else existing.get("score"),
            "first_seen": existing.get("first_seen", now),
            "updated": now,
        }
        self._save()

    def mark_many(self, offers: Iterable[JobOffer], status: str) -> None:
        """Bulk update — single save."""
        if status not in VALID_STATUSES:
            raise ValueError(f"Statut invalide : {status}")
        now = datetime.now().isoformat(timespec="seconds")
        for offer in offers:
            key = offer.unique_key()
            existing = self._data["offers"].get(key, {})
            # Don't downgrade favorite/applied to "seen"
            if status == "seen" and existing.get("status") in ("favorite", "applied"):
                continue
            self._data["offers"][key] = {
                "id": offer.id,
                "title": offer.title,
                "company": offer.company,
                "url": offer.url,
                "source": offer.source,
                "status": status,
                "score": offer.match_score if offer.match_score is not None else existing.get("score"),
                "first_seen": existing.get("first_seen", now),
                "updated": now,
            }
        self._save()

    def list_by_status(self, status: str) -> list[dict]:
        return [
            entry for entry in self._data["offers"].values()
            if entry.get("status") == status
        ]
