"""
Données de localisation : pays supportés, régions françaises, et
correspondances par source (Adzuna a un endpoint par pays, Indeed et
Talent.com un domaine par pays, France Travail est France uniquement).
"""
import unicodedata

# (code, nom affiché) — le code pilote les endpoints des scrapers
COUNTRIES: list[tuple[str, str]] = [
    ("fr", "France"),
    ("be", "Belgique"),
    ("ch", "Suisse"),
    ("lu", "Luxembourg"),
    ("de", "Allemagne"),
    ("es", "Espagne"),
    ("it", "Italie"),
    ("nl", "Pays-Bas"),
    ("pt", "Portugal"),
    ("gb", "Royaume-Uni"),
    ("ca", "Canada"),
    ("us", "États-Unis"),
]

COUNTRY_NAMES = {code: name for code, name in COUNTRIES}

# Pays couverts par l'API Adzuna (https://developer.adzuna.com/docs)
ADZUNA_COUNTRIES = {"fr", "be", "ch", "de", "es", "it", "nl", "gb", "ca", "us"}

# Domaine Indeed par pays
INDEED_DOMAINS = {
    "fr": "fr.indeed.com",
    "be": "be.indeed.com",
    "ch": "ch.indeed.com",
    "lu": "lu.indeed.com",
    "de": "de.indeed.com",
    "es": "es.indeed.com",
    "it": "it.indeed.com",
    "nl": "nl.indeed.com",
    "pt": "pt.indeed.com",
    "gb": "uk.indeed.com",
    "ca": "ca.indeed.com",
    "us": "www.indeed.com",
}

# Domaine Talent.com par pays (sous-domaines pays ; www = international/US)
TALENT_DOMAINS = {
    "fr": "fr.talent.com",
    "be": "be.talent.com",
    "ch": "ch.talent.com",
    "lu": "lu.talent.com",
    "de": "de.talent.com",
    "es": "es.talent.com",
    "it": "it.talent.com",
    "nl": "nl.talent.com",
    "pt": "pt.talent.com",
    "gb": "uk.talent.com",
    "ca": "ca.talent.com",
    "us": "www.talent.com",
}

# Régions françaises (métropole + outre-mer)
FR_REGIONS: list[str] = [
    "Auvergne-Rhône-Alpes",
    "Bourgogne-Franche-Comté",
    "Bretagne",
    "Centre-Val de Loire",
    "Corse",
    "Grand Est",
    "Hauts-de-France",
    "Île-de-France",
    "Normandie",
    "Nouvelle-Aquitaine",
    "Occitanie",
    "Pays de la Loire",
    "Provence-Alpes-Côte d'Azur",
    "Guadeloupe",
    "Martinique",
    "Guyane",
    "La Réunion",
    "Mayotte",
]


def _fold(text: str) -> str:
    """Minuscules sans accents — pour la recherche tolérante ('ile' = 'Île')."""
    decomposed = unicodedata.normalize("NFKD", text.lower())
    return "".join(c for c in decomposed if not unicodedata.combining(c))


def search_names(query: str, names: list[str]) -> list[str]:
    """Recherche insensible à la casse et aux accents dans une liste de noms.
    Les correspondances en début de nom sont prioritaires."""
    q = _fold(query.strip())
    if not q:
        return []
    starts = [n for n in names if _fold(n).startswith(q)]
    contains = [n for n in names if q in _fold(n) and n not in starts]
    return starts + contains
