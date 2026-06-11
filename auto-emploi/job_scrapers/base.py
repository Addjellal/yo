import re
import urllib.parse
from dataclasses import dataclass, field
from typing import Optional
from datetime import datetime

# Garde-fou mémoire : une réponse HTTP plus grosse que ça est suspecte
MAX_RESPONSE_BYTES = 10 * 1024 * 1024

# Caractères de contrôle (sauf \n et \t, conservés dans les descriptions)
_CTRL_RE = re.compile(r"[\x00-\x08\x0b\x0c\x0e-\x1f\x7f]")
_WS_RE = re.compile(r"\s+")

# Longueurs maximales par champ : les données viennent du web, on borne tout
_LIMITS = {
    "id": 120, "title": 300, "company": 200, "location": 200,
    "salary": 120, "contract_type": 80, "source": 60,
    "url": 2000, "apply_url": 2000, "description": 20000,
}


def _clean_line(value: Optional[str], limit: int) -> str:
    """Champ mono-ligne : caractères de contrôle supprimés, espaces normalisés."""
    if not value:
        return ""
    value = _CTRL_RE.sub("", str(value).replace("\n", " ").replace("\t", " "))
    return _WS_RE.sub(" ", value).strip()[:limit]


def _clean_block(value: Optional[str], limit: int) -> str:
    """Champ multi-lignes (description) : contrôle supprimés, \\n/\\t conservés."""
    if not value:
        return ""
    return _CTRL_RE.sub("", str(value)).strip()[:limit]


def safe_url(value: Optional[str], limit: int = 2000) -> str:
    """N'accepte que les URLs http(s) absolues — tout le reste devient ''.
    Empêche les liens javascript:/file:/data: injectés par une offre hostile."""
    if not value:
        return ""
    value = str(value).strip()[:limit]
    try:
        parsed = urllib.parse.urlparse(value)
    except ValueError:
        return ""
    if parsed.scheme not in ("http", "https") or not parsed.netloc:
        return ""
    return value


@dataclass
class JobOffer:
    id: str
    title: str
    company: str
    location: str
    description: str
    url: str
    source: str
    salary: Optional[str] = None
    contract_type: Optional[str] = None
    posted_date: Optional[datetime] = None
    apply_url: Optional[str] = None
    match_score: Optional[int] = None
    match_reasons: Optional[str] = None
    match_strengths: Optional[str] = None  # ce que le CV apporte précisément
    match_gaps: Optional[str] = None       # ce qui manque pour ce poste

    def __post_init__(self):
        # Sanitisation systématique : quel que soit le scraper, aucune donnée
        # brute du web n'entre dans l'application sans être bornée et nettoyée.
        self.id = _clean_line(self.id, _LIMITS["id"])
        self.title = _clean_line(self.title, _LIMITS["title"])
        self.company = _clean_line(self.company, _LIMITS["company"]) or "N/A"
        self.location = _clean_line(self.location, _LIMITS["location"])
        self.source = _clean_line(self.source, _LIMITS["source"])
        self.salary = _clean_line(self.salary, _LIMITS["salary"]) or None
        self.contract_type = _clean_line(self.contract_type, _LIMITS["contract_type"]) or None
        self.description = _clean_block(self.description, _LIMITS["description"])
        self.url = safe_url(self.url, _LIMITS["url"])
        self.apply_url = safe_url(self.apply_url, _LIMITS["apply_url"])

    def to_text(self) -> str:
        parts = [
            f"Poste : {self.title}",
            f"Entreprise : {self.company}",
            f"Lieu : {self.location}",
        ]
        if self.contract_type:
            parts.append(f"Contrat : {self.contract_type}")
        if self.salary:
            parts.append(f"Salaire : {self.salary}")
        parts.append(f"\nDescription :\n{self.description[:3000]}")
        return "\n".join(parts)

    def unique_key(self) -> str:
        # Le lieu fait partie de la clé : deux postes identiques de la même
        # entreprise dans deux villes sont des offres distinctes.
        return (
            f"{self.title.lower().strip()}|{self.company.lower().strip()}"
            f"|{self.location.lower().strip()}"
        )

    def legacy_key(self) -> str:
        """Ancienne clé (sans lieu) : permet de retrouver le statut des offres
        trackées avant le changement de format — l'historique n'est pas perdu."""
        return f"{self.title.lower().strip()}|{self.company.lower().strip()}"


class BaseScraper:
    source_name: str = "unknown"

    def search(self, query: str, location: str = "", max_results: int = 50) -> list[JobOffer]:
        raise NotImplementedError
