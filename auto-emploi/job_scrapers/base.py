import html as _html
import re
import time
import urllib.parse
from dataclasses import dataclass
from typing import Callable, Optional

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


# Détection de balisage HTML résiduel dans une description (certaines APIs
# renvoient du HTML brut : <p>, <li>, <br>, entités &amp;…)
_TAG_RE = re.compile(r"<(?:br|/p|/li|/div|/tr)\s*/?>", re.IGNORECASE)
_ANY_TAG_RE = re.compile(r"<[^>\n]{1,200}>")
_MULTI_NL_RE = re.compile(r"\n{3,}")


def strip_html(text: str) -> str:
    """Nettoie le HTML résiduel d'une description : balises de bloc → sauts de
    ligne, autres balises supprimées, entités décodées. Sans effet sur du
    texte brut (aucune balise détectée)."""
    if "<" not in text and "&" not in text:
        return text
    text = _TAG_RE.sub("\n", text)
    text = _ANY_TAG_RE.sub(" ", text)
    text = _html.unescape(text)
    # Re-passe : des entités décodées peuvent révéler des balises encodées
    if _ANY_TAG_RE.search(text):
        text = _ANY_TAG_RE.sub(" ", text)
    lines = [" ".join(line.split()) for line in text.split("\n")]
    return _MULTI_NL_RE.sub("\n\n", "\n".join(lines)).strip()


def _clean_block(value: Optional[str], limit: int) -> str:
    """Champ multi-lignes (description) : contrôle supprimés, \\n/\\t conservés,
    HTML résiduel nettoyé."""
    if not value:
        return ""
    return strip_html(_CTRL_RE.sub("", str(value)).strip())[:limit]


# ─── Extraction de sections (missions / profil / compétences) ────────────────
# Titres de sections fréquents dans les offres FR/EN — heuristique code pur,
# aucun appel IA. Sert à structurer la description pour le matching.
_SECTION_PATTERNS: list[tuple[str, re.Pattern]] = [
    ("missions", re.compile(
        r"^\s*(?:vos\s+|les\s+|tes\s+)?(?:missions?|responsabilit[ée]s?|le\s+poste|"
        r"your\s+(?:missions?|responsibilit(?:y|ies))|the\s+role|what\s+you.?ll\s+do)\s*:?\s*$",
        re.IGNORECASE)),
    ("profil", re.compile(
        r"^\s*(?:votre\s+|le\s+|ton\s+)?(?:profil(?:\s+recherch[ée])?|"
        r"qui\s+(?:êtes|es)[- ](?:vous|tu)|about\s+you|who\s+you\s+are|"
        r"your\s+profile|requirements?|qualifications?)\s*:?\s*$",
        re.IGNORECASE)),
    ("competences", re.compile(
        r"^\s*(?:comp[ée]tences?(?:\s+(?:requises?|techniques?|attendues?))?|"
        r"skills?(?:\s+(?:required|needed))?|stack(?:\s+technique)?|"
        r"technologies?|outils?)\s*:?\s*$",
        re.IGNORECASE)),
]


def extract_sections(description: str) -> dict[str, str]:
    """Découpe une description en sections (missions, profil, competences)
    d'après les titres usuels. Retourne {} si aucun titre n'est détecté —
    l'appelant garde alors la description brute."""
    sections: dict[str, list[str]] = {}
    current: str | None = None
    for line in (description or "").split("\n"):
        matched = next(
            (name for name, pat in _SECTION_PATTERNS if pat.match(line.strip())),
            None,
        )
        if matched:
            current = matched
            sections.setdefault(current, [])
        elif current:
            sections[current].append(line)
    return {
        name: "\n".join(lines).strip()
        for name, lines in sections.items() if "\n".join(lines).strip()
    }


# ─── Retries et cache de secours (APIs externes instables) ───────────────────

# Délais avant nouvel essai : 2 s, 4 s, 8 s (exponentiel)
RETRY_DELAYS = (2.0, 4.0, 8.0)

# Dernier résultat réussi par (source, requête, lieu) — secours en mémoire si
# l'API externe tombe en panne au scan suivant dans la même session.
_RESULT_CACHE: dict[tuple[str, str, str], list["JobOffer"]] = {}


def fetch_with_retry(send: Callable[[], "object"], source: str,
                     log: Callable[[str], None] = lambda m: None):
    """Exécute `send()` (qui retourne un requests.Response) avec retries
    exponentiels sur les erreurs 5xx et les erreurs réseau. Les erreurs 4xx ne
    sont PAS retentées (la requête est en cause, pas le serveur).
    Lève la dernière exception si tous les essais échouent."""
    import requests

    last_error: Exception | None = None
    for attempt, delay in enumerate((*RETRY_DELAYS, None)):
        try:
            resp = send()
            if resp.status_code >= 500:
                last_error = requests.HTTPError(
                    f"HTTP {resp.status_code} (erreur côté serveur {source})",
                    response=resp,
                )
                raise last_error
            return resp
        except requests.RequestException as e:
            last_error = e
            if delay is None:
                break
            log(f"[{source}] Tentative {attempt + 1} échouée ({type(e).__name__}) — "
                f"nouvel essai dans {delay:.0f} s…")
            time.sleep(delay)
    raise last_error  # type: ignore[misc]


def cache_results(source: str, query: str, location: str,
                  offers: list["JobOffer"]) -> None:
    if offers:
        _RESULT_CACHE[(source, query.lower().strip(), location.lower().strip())] = list(offers)


def cached_results(source: str, query: str, location: str) -> list["JobOffer"] | None:
    return _RESULT_CACHE.get((source, query.lower().strip(), location.lower().strip()))


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
    apply_url: Optional[str] = None
    match_score: Optional[int] = None
    match_reasons: Optional[str] = None
    match_strengths: Optional[str] = None  # ce que le CV apporte précisément
    match_gaps: Optional[str] = None       # ce qui manque pour ce poste
    # Matching multi-CV : résultat par CV {label: {score, reasons, strengths, gaps}}
    # et label du CV au meilleur score (les champs match_* portent ce meilleur résultat)
    cv_scores: Optional[dict] = None
    best_cv: Optional[str] = None

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
        # Sections détectées (missions/profil/compétences) : mises en avant
        # pour le matching, le reste de la description suit dans le budget.
        sections = extract_sections(self.description)
        budget = 3000
        for name, label in (("missions", "Missions"), ("profil", "Profil recherché"),
                            ("competences", "Compétences")):
            if name in sections and budget > 200:
                chunk = sections[name][:budget]
                budget -= len(chunk)
                parts.append(f"\n{label} :\n{chunk}")
        if budget > 200:
            parts.append(f"\nDescription :\n{self.description[:budget]}")
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
