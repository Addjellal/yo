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

# Grandes villes par pays (préfectures + villes importantes, exonymes français
# usuels). Sert de repli hors-ligne à l'autocomplétion et de source de
# suggestions pour les pays autres que la France (où l'on interroge en ligne
# l'API officielle geo.api.gouv.fr, bien plus complète).
MAJOR_CITIES: dict[str, list[str]] = {
    "fr": [
        "Paris", "Marseille", "Lyon", "Toulouse", "Nice", "Nantes", "Montpellier",
        "Strasbourg", "Bordeaux", "Lille", "Rennes", "Reims", "Saint-Étienne",
        "Le Havre", "Toulon", "Grenoble", "Dijon", "Angers", "Nîmes", "Villeurbanne",
        "Clermont-Ferrand", "Aix-en-Provence", "Le Mans", "Brest", "Tours", "Amiens",
        "Limoges", "Annecy", "Perpignan", "Boulogne-Billancourt", "Metz", "Besançon",
        "Orléans", "Rouen", "Mulhouse", "Caen", "Nancy", "Tourcoing", "Roubaix",
        "Nanterre", "Avignon", "Créteil", "Dunkerque", "Poitiers", "Versailles",
        "Courbevoie", "Cherbourg", "Béziers", "La Rochelle", "Calais", "Bourges",
        "Antibes", "Cannes", "Mérignac", "Ajaccio", "Saint-Nazaire", "Colmar",
        "Issy-les-Moulineaux", "Levallois-Perret", "Quimper", "Valence", "Pau",
        "Troyes", "Niort", "Lorient", "Chambéry", "Saint-Quentin", "Bayonne",
        "Beauvais", "Cholet", "Vénissieux", "Hyères", "Fréjus", "Narbonne", "Vannes",
        "Arles", "Montauban", "Évry-Courcouronnes", "La Roche-sur-Yon", "Belfort",
        "Charleville-Mézières", "Tarbes", "Angoulême", "Châteauroux", "Laval",
        "Roanne", "Saint-Malo", "Biarritz", "Albi", "Carcassonne", "Bastia",
    ],
    "be": ["Bruxelles", "Anvers", "Gand", "Charleroi", "Liège", "Bruges", "Namur",
           "Louvain", "Mons", "Alost", "Malines", "La Louvière", "Courtrai",
           "Hasselt", "Ostende", "Tournai", "Wavre", "Arlon"],
    "ch": ["Zurich", "Genève", "Bâle", "Lausanne", "Berne", "Winterthour", "Lucerne",
           "Saint-Gall", "Lugano", "Bienne", "Thoune", "Fribourg", "Neuchâtel",
           "Sion", "Coire", "Zoug"],
    "lu": ["Luxembourg", "Esch-sur-Alzette", "Differdange", "Dudelange",
           "Ettelbruck", "Diekirch"],
    "de": ["Berlin", "Munich", "Hambourg", "Cologne", "Francfort", "Stuttgart",
           "Düsseldorf", "Dortmund", "Essen", "Leipzig", "Brême", "Dresde",
           "Hanovre", "Nuremberg", "Duisbourg", "Bonn", "Mannheim", "Karlsruhe",
           "Münster", "Aix-la-Chapelle"],
    "es": ["Madrid", "Barcelone", "Valence", "Séville", "Saragosse", "Malaga",
           "Murcie", "Palma", "Bilbao", "Alicante", "Cordoue", "Valladolid", "Vigo",
           "Gijón", "Grenade", "La Corogne", "Saint-Sébastien", "Pampelune"],
    "it": ["Rome", "Milan", "Naples", "Turin", "Palerme", "Gênes", "Bologne",
           "Florence", "Bari", "Catane", "Venise", "Vérone", "Messine", "Padoue",
           "Trieste", "Brescia", "Parme", "Modène"],
    "nl": ["Amsterdam", "Rotterdam", "La Haye", "Utrecht", "Eindhoven", "Tilbourg",
           "Groningue", "Almere", "Breda", "Nimègue", "Enschede", "Haarlem",
           "Arnhem", "Amersfoort", "Bois-le-Duc", "Maastricht"],
    "pt": ["Lisbonne", "Porto", "Vila Nova de Gaia", "Amadora", "Braga", "Coimbra",
           "Funchal", "Setúbal", "Almada", "Faro", "Aveiro", "Évora"],
    "gb": ["Londres", "Birmingham", "Manchester", "Glasgow", "Liverpool", "Leeds",
           "Sheffield", "Édimbourg", "Bristol", "Cardiff", "Belfast", "Leicester",
           "Nottingham", "Newcastle", "Brighton", "Cambridge", "Oxford", "Aberdeen"],
    "ca": ["Montréal", "Toronto", "Vancouver", "Calgary", "Ottawa", "Edmonton",
           "Québec", "Winnipeg", "Hamilton", "Halifax", "Victoria", "Gatineau",
           "Sherbrooke", "Trois-Rivières", "Laval", "Longueuil"],
    "us": ["New York", "Los Angeles", "Chicago", "Houston", "Phoenix", "Philadelphie",
           "San Antonio", "San Diego", "Dallas", "San José", "Austin",
           "San Francisco", "Seattle", "Boston", "Denver", "Washington", "Atlanta",
           "Miami", "Portland", "Las Vegas"],
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


def suggest_locations(country: str, query: str, limit: int = 8) -> list[dict]:
    """Suggestions pour l'autocomplétion de localisation : régions (France) puis
    grandes villes du pays, filtrées par search_names (tolérant casse/accents).
    Repli hors-ligne et source pour les pays autres que la France."""
    country = (country or "fr").strip().lower()
    out: list[dict] = []
    seen: set[str] = set()

    def _add(name: str, kind: str) -> None:
        key = name.lower()
        if key not in seen:
            seen.add(key)
            out.append({"value": name, "label": name, "type": kind})

    if country == "fr":
        for name in search_names(query, FR_REGIONS):
            _add(name, "region")
    for name in search_names(query, MAJOR_CITIES.get(country, [])):
        _add(name, "city")
    return out[:limit]
