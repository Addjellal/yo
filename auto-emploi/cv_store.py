"""
Registre des CV connus : labels, profils structurés extraits par l'IA et
corrections manuelles de l'utilisateur.

Stockage : OUTPUT_DIR/.cvs.json — même style que le tracker et l'historique
(JSON unique, écriture atomique, fichier corrompu mis de côté).
Schéma :
    {
        "cvs": [
            {
                "id": "a1b2c3d4",
                "filename": "mon_cv.pdf",     # fichier dans le dossier projet
                "label": "CV Data 2026",      # libellé modifiable
                "added": "2026-06-12T10:00:00",
                "analyzed": "",               # date de la dernière extraction IA
                "deleted": false,             # tombstone : l'historique garde le nom
                "deleted_date": "",
                "profile": { ... },           # extraction IA (voir sections ci-dessous)
                "overrides": { ... }          # sections corrigées à la main (prioritaires)
            }
        ]
    }

Sections d'un profil : contact, skills, experiences, education, languages.
Une section présente dans "overrides" prime sur "profile" pour tous les
usages (matching, lettres) — c'est la garantie « le manuel gagne ».
"""
import json
import os
import secrets
import tempfile
from datetime import datetime
from pathlib import Path

_MAX_CVS = 100
_MAX_STORE_BYTES = 20 * 1024 * 1024

PROFILE_SECTIONS = ("contact", "skills", "experiences", "education", "languages")

CV_EXTENSIONS = (".pdf", ".docx", ".txt")
EXCLUDED_FILENAMES = {"requirements.txt", "robots.txt"}


def list_cv_files(directory: Path) -> list[str]:
    """Fichiers CV présents dans un dossier (PDF/DOCX/TXT, pas de dotfiles) —
    partagé par le CLI et le serveur web."""
    files = []
    try:
        entries = sorted(directory.iterdir())
    except OSError:
        return []
    for path in entries:
        if not path.is_file() or path.name.startswith("."):
            continue
        if path.suffix.lower() not in CV_EXTENSIONS:
            continue
        if path.name.lower() in EXCLUDED_FILENAMES:
            continue
        files.append(path.name)
    return files

# Bornes par champ : les données viennent d'un LLM ou d'un formulaire web
_CONTACT_LIMITS = {"name": 80, "headline": 120, "email": 120, "phone": 40, "city": 80}


def _s(value, limit: int) -> str:
    """Chaîne nettoyée et bornée (les retours à la ligne deviennent des espaces)."""
    return " ".join(str(value or "").split())[:limit]


def _clean_profile(raw: dict) -> dict:
    """Valide et borne un profil (extraction IA ou formulaire web) : seules les
    sections et champs connus sont conservés, tout est typé et plafonné."""
    raw = raw if isinstance(raw, dict) else {}
    out: dict = {}

    contact = raw.get("contact")
    if isinstance(contact, dict):
        cleaned = {k: _s(contact.get(k), lim) for k, lim in _CONTACT_LIMITS.items()}
        if any(cleaned.values()):
            out["contact"] = cleaned

    skills = []
    for cat in (raw.get("skills") or [])[:12]:
        if not isinstance(cat, dict):
            continue
        items = [_s(i, 60) for i in (cat.get("items") or [])[:30] if _s(i, 60)]
        category = _s(cat.get("category"), 60)
        if items:
            skills.append({"category": category or "Autres", "items": items})
    if skills:
        out["skills"] = skills

    experiences = []
    for exp in (raw.get("experiences") or [])[:20]:
        if not isinstance(exp, dict):
            continue
        entry = {
            "title": _s(exp.get("title"), 120),
            "company": _s(exp.get("company"), 120),
            "start": _s(exp.get("start"), 20),
            "end": _s(exp.get("end"), 20),
            "description": str(exp.get("description") or "").strip()[:500],
        }
        if entry["title"] or entry["company"]:
            experiences.append(entry)
    if experiences:
        out["experiences"] = experiences

    education = []
    for edu in (raw.get("education") or [])[:10]:
        if not isinstance(edu, dict):
            continue
        entry = {
            "degree": _s(edu.get("degree"), 150),
            "school": _s(edu.get("school"), 120),
            "year": _s(edu.get("year"), 20),
        }
        if entry["degree"] or entry["school"]:
            education.append(entry)
    if education:
        out["education"] = education

    languages = []
    for lang in (raw.get("languages") or [])[:10]:
        if not isinstance(lang, dict):
            continue
        entry = {"name": _s(lang.get("name"), 40), "level": _s(lang.get("level"), 60)}
        if entry["name"]:
            languages.append(entry)
    if languages:
        out["languages"] = languages

    return out


def render_profile(profile: dict) -> str:
    """Rend un profil en texte lisible — utilisé dans les prompts (matching,
    lettres) et pour l'affichage CLI."""
    lines: list[str] = []
    contact = profile.get("contact") or {}
    contact_bits = [contact.get(k, "") for k in ("name", "headline", "city", "email", "phone")]
    if any(contact_bits):
        lines.append(" · ".join(b for b in contact_bits if b))
    for cat in profile.get("skills") or []:
        lines.append(f"Compétences ({cat['category']}) : {', '.join(cat['items'])}")
    for exp in profile.get("experiences") or []:
        period = "–".join(p for p in (exp.get("start"), exp.get("end")) if p)
        head = " — ".join(p for p in (exp.get("title"), exp.get("company")) if p)
        lines.append(f"Expérience : {head}" + (f" ({period})" if period else ""))
        if exp.get("description"):
            lines.append(f"  {exp['description']}")
    for edu in profile.get("education") or []:
        head = " — ".join(p for p in (edu.get("degree"), edu.get("school")) if p)
        lines.append(f"Formation : {head}" + (f" ({edu['year']})" if edu.get("year") else ""))
    langs = profile.get("languages") or []
    if langs:
        lines.append("Langues : " + ", ".join(
            f"{lg['name']}{' (' + lg['level'] + ')' if lg.get('level') else ''}" for lg in langs
        ))
    return "\n".join(lines)


class CVStore:
    def __init__(self, store_path: Path):
        self.path = store_path
        self.path.parent.mkdir(parents=True, exist_ok=True)
        self._data: dict = self._load()

    def _load(self) -> dict:
        empty = {"cvs": []}
        if not self.path.exists():
            return empty
        try:
            if self.path.stat().st_size > _MAX_STORE_BYTES:
                raise ValueError("fichier anormalement volumineux")
            data = json.loads(self.path.read_text(encoding="utf-8"))
            if not isinstance(data, dict) or not isinstance(data.get("cvs"), list):
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
            dir=str(self.path.parent), prefix=".cvs_", suffix=".tmp"
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
        # Un profil de CV est une donnée personnelle : accès propriétaire seul
        if os.name != "nt":
            try:
                os.chmod(self.path, 0o600)
            except OSError:
                pass

    # ─── Lecture ──────────────────────────────────────────────────────────────

    def list_cvs(self, include_deleted: bool = False) -> list[dict]:
        return [
            e for e in self._data["cvs"]
            if include_deleted or not e.get("deleted")
        ]

    def get(self, ref: str) -> dict | None:
        """Retrouve un CV actif par id, nom de fichier ou label (insensible à
        la casse pour le label). Les tombstones ne sont jamais retournés ici."""
        ref = str(ref or "").strip()
        if not ref:
            return None
        active = [e for e in self._data["cvs"] if not e.get("deleted")]
        for entry in active:
            if entry.get("id") == ref:
                return entry
        for entry in active:
            if entry.get("filename") == ref:
                return entry
        folded = ref.lower()
        for entry in active:
            if str(entry.get("label", "")).lower() == folded:
                return entry
        return None

    def history_label(self, filename: str, file_exists: bool) -> str:
        """Libellé d'un CV référencé par l'historique : « CV supprimé : x »
        après suppression, « x (fichier introuvable) » si l'entrée est active
        mais que le fichier a disparu (ex. CV hors du dossier projet)."""
        filename = str(filename or "")
        if not filename:
            return ""
        entry = self.get(filename)
        if entry is not None:
            label = entry.get("label") or filename
            return label if file_exists else f"{label} (fichier introuvable)"
        # Tombstone le plus récent pour ce nom de fichier, sinon nom brut
        for e in reversed(self._data["cvs"]):
            if e.get("filename") == filename and e.get("deleted"):
                return f"CV supprimé : {e.get('label') or filename}"
        if file_exists:
            return filename
        return f"CV supprimé : {filename}"

    @staticmethod
    def effective_profile(entry: dict) -> tuple[dict, dict]:
        """Profil fusionné (manuel > IA) + provenance par section :
        retourne (profile, sources) avec sources[section] ∈ {"manual", "ai"}."""
        profile: dict = {}
        sources: dict = {}
        extracted = entry.get("profile") or {}
        overrides = entry.get("overrides") or {}
        for section in PROFILE_SECTIONS:
            if section in overrides:
                profile[section] = overrides[section]
                sources[section] = "manual"
            elif section in extracted:
                profile[section] = extracted[section]
                sources[section] = "ai"
        return profile, sources

    def effective_text(self, entry: dict, raw_text: str) -> str:
        """Texte du CV à donner aux IA : texte brut + sections corrigées
        manuellement, annoncées comme prioritaires sur le contenu du fichier."""
        overrides = entry.get("overrides") or {}
        if not overrides:
            return raw_text
        rendered = render_profile(overrides)
        if not rendered:
            return raw_text
        return (
            f"{raw_text}\n\n"
            "=== INFORMATIONS VÉRIFIÉES PAR LE CANDIDAT "
            "(elles priment sur le CV ci-dessus en cas de différence) ===\n"
            f"{rendered}"
        )

    # ─── Écriture ─────────────────────────────────────────────────────────────

    def register(self, filename: str, label: str = "") -> dict:
        """Enregistre un CV (idempotent : un fichier déjà actif est retourné
        tel quel). Après une suppression, ré-uploader le même nom crée une
        entrée neuve — le tombstone reste pour l'historique."""
        filename = str(filename or "").strip()[:200]
        if not filename:
            raise ValueError("Nom de fichier vide")
        existing = self.get(filename)
        if existing is not None:
            return existing
        entry = {
            "id": secrets.token_hex(4),
            "filename": filename,
            "label": _s(label, 80) or Path(filename).stem,
            "added": datetime.now().isoformat(timespec="seconds"),
            "analyzed": "",
            "deleted": False,
            "deleted_date": "",
            "profile": {},
            "overrides": {},
        }
        self._data["cvs"].append(entry)
        if len(self._data["cvs"]) > _MAX_CVS:
            # Plafond : on purge d'abord les tombstones (les plus anciens d'abord)
            # — jamais un CV actif tant qu'il reste une entrée supprimée à éliminer.
            cvs = self._data["cvs"]
            while len(cvs) > _MAX_CVS:
                idx = next((i for i, e in enumerate(cvs) if e.get("deleted")), None)
                if idx is None:
                    break
                cvs.pop(idx)
            # S'il ne reste que des CV actifs au-delà du plafond, on conserve les
            # plus récents (les seuls perdus possibles sont alors des CV actifs).
            if len(cvs) > _MAX_CVS:
                self._data["cvs"] = cvs[-_MAX_CVS:]
        self._save()
        return entry

    def sync(self, filenames: list[str]) -> None:
        """Enregistre tous les fichiers CV présents non encore connus
        (CV déposés à la main dans le dossier, ou utilisés via le CLI)."""
        changed = False
        for name in filenames:
            if self.get(name) is None:
                try:
                    self.register(name)
                    changed = True
                except ValueError:
                    continue
        if changed:
            self._save()

    def set_label(self, cv_id: str, label: str) -> bool:
        entry = self.get(cv_id)
        if entry is None:
            return False
        entry["label"] = _s(label, 80) or entry["label"]
        self._save()
        return True

    def set_profile(self, cv_id: str, profile: dict) -> bool:
        """Remplace l'extraction IA (les corrections manuelles sont conservées
        et restent prioritaires)."""
        entry = self.get(cv_id)
        if entry is None:
            return False
        entry["profile"] = _clean_profile(profile)
        entry["analyzed"] = datetime.now().isoformat(timespec="seconds")
        self._save()
        return True

    def set_overrides(self, cv_id: str, overrides: dict) -> bool:
        """Enregistre les sections corrigées manuellement. Une section absente
        ou vide dans le payload est retirée : retour à l'extraction IA."""
        entry = self.get(cv_id)
        if entry is None:
            return False
        cleaned = _clean_profile(overrides)
        entry["overrides"] = cleaned
        self._save()
        return True

    def mark_deleted(self, cv_id: str) -> dict | None:
        """Tombstone : le CV disparaît des listes actives mais l'historique
        garde son nom (« CV supprimé : x »). Retourne l'entrée, ou None."""
        entry = self.get(cv_id)
        if entry is None:
            return None
        entry["deleted"] = True
        entry["deleted_date"] = datetime.now().isoformat(timespec="seconds")
        # Le profil reste stocké : inutile pour le matching, mais sans danger
        self._save()
        return entry
