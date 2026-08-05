"""
Analyse des compétences demandées — 100 % code, aucun appel IA.

Compare ce que RÉCLAMENT les offres déjà collectées à ce que MENTIONNE le CV,
pour répondre à une question que l'app ne traitait pas : « qu'est-ce qui revient
sans arrêt dans les annonces de mon métier et que mon CV ne dit pas ? »

Le vocabulaire est volontairement figé (pas d'extraction libre) : une liste
contrôlée évite le bruit des mots vides et reste explicable à l'utilisateur.
Chaque compétence a des alias (FR/EN, abréviations, graphies) ramenés à un nom
canonique. Le texte est replié (sans accent, minuscules) puis balayé en UNE
passe par une regex unique — coût linéaire même sur des centaines d'offres.
"""
import re
import unicodedata
from collections import Counter

# ─── Vocabulaire contrôlé : canonique -> alias ───────────────────────────────
# Les alias sont écrits SANS accent et en minuscules (le texte est replié avant
# comparaison). Les caractères regex (+, ., #) sont échappés automatiquement.
_SKILLS: dict[str, tuple[str, ...]] = {
    # Langages
    "C": ("c", "langage c"),
    "C++": ("c++", "cpp"),
    "C#": ("c#", "csharp"),
    "Python": ("python",),
    "Java": ("java",),
    "JavaScript": ("javascript", "js"),
    "TypeScript": ("typescript",),
    "Rust": ("rust",),
    "Go": ("golang",),
    "VHDL": ("vhdl",),
    "Verilog": ("verilog", "systemverilog"),
    "Assembleur": ("assembleur", "assembly", "asm"),
    "SQL": ("sql",),
    "Bash": ("bash", "shell script", "scripting shell"),
    "MATLAB": ("matlab", "simulink"),
    "PHP": ("php",),
    "Kotlin": ("kotlin",),
    "Swift": ("swift",),

    # Embarqué / temps réel
    "Microcontrôleurs": ("microcontroleur", "microcontroleurs", "mcu"),
    "STM32": ("stm32",),
    "ARM Cortex": ("arm cortex", "cortex-m", "cortex m", "arm"),
    "FreeRTOS": ("freertos",),
    "RTOS / temps réel": ("rtos", "temps reel", "real-time", "real time"),
    "Baremetal": ("baremetal", "bare-metal", "bare metal"),
    "Linux embarqué": ("linux embarque", "embedded linux", "yocto", "buildroot"),
    "Drivers / BSP": ("driver", "drivers", "bsp", "pilote bas niveau"),
    "Noyau Linux": ("kernel linux", "linux kernel", "noyau linux"),
    "I2C": ("i2c",),
    "SPI": ("spi",),
    "UART": ("uart", "rs232", "rs-232"),
    "CAN bus": ("can bus", "canbus", "bus can", "canopen"),
    "Modbus": ("modbus",),
    "Ethernet / TCP-IP": ("tcp/ip", "tcp-ip", "ethernet"),
    "DMA": ("dma",),
    "Oscilloscope / debug HW": ("oscilloscope", "analyseur logique", "jtag", "swd"),
    "Électronique": ("electronique", "schema electronique", "altium", "kicad"),

    # Automatisme / industrie
    "Automates (PLC)": ("automate programmable", "automates", "plc"),
    "Siemens TIA Portal": ("tia portal", "step 7", "step7", "siemens"),
    "Schneider": ("schneider", "unity pro", "ecostruxure"),
    "SCADA / IHM": ("scada", "ihm", "supervision industrielle", "wincc"),
    "Grafcet": ("grafcet", "sfc"),

    # Qualité / sûreté
    "Tests unitaires": ("test unitaire", "tests unitaires", "unit test", "unit tests"),
    "Tests d'intégration": ("test d'integration", "tests d'integration", "integration test"),
    "CI/CD": ("ci/cd", "ci-cd", "integration continue", "jenkins", "gitlab ci", "github actions"),
    "Git": ("git", "gitlab", "github", "versioning"),
    "DO-178": ("do-178", "do178"),
    "ISO 26262": ("iso 26262", "iso26262"),
    "IEC 61508": ("iec 61508", "61508"),
    "MISRA": ("misra",),
    "Sûreté de fonctionnement": ("surete de fonctionnement", "safety critical", "critique securite"),
    "Cybersécurité": ("cybersecurite", "cyber securite", "securite informatique", "cybersecurity"),

    # Méthodes / outils
    "Agile / Scrum": ("agile", "scrum", "kanban", "safe"),
    "Docker": ("docker", "conteneurisation", "container"),
    "Kubernetes": ("kubernetes", "k8s"),
    "Cloud (AWS/Azure/GCP)": ("aws", "azure", "gcp", "google cloud"),
    "Jira": ("jira",),
    "Doors / exigences": ("doors", "gestion des exigences", "ingenierie des exigences"),
    "UML / SysML": ("uml", "sysml"),
    "Documentation technique": ("documentation technique", "redaction technique"),

    # Data / IA
    "Machine learning": ("machine learning", "apprentissage automatique", "deep learning"),
    "Traitement du signal": ("traitement du signal", "signal processing", "dsp"),
    "Vision par ordinateur": ("vision par ordinateur", "computer vision", "opencv"),

    # Transverses
    "Anglais": ("anglais", "english", "anglais technique"),
    "Allemand": ("allemand", "german"),
    "Travail en équipe": ("travail en equipe", "esprit d'equipe", "teamwork"),
    "Autonomie": ("autonomie", "autonome"),
    "Gestion de projet": ("gestion de projet", "chef de projet", "project management"),
    "Relation client": ("relation client", "relationnel client", "customer facing"),
    "Encadrement": ("encadrement", "management d'equipe", "mentorat", "tutorat"),
}

# Alias trop courts ou trop polysémiques : exigent une frontière de mot stricte
# et ne sont jamais cherchés en sous-chaîne (« c » ne doit pas matcher « avec »).
_SHORT_ALIASES = {"c", "r", "go", "js", "sql", "spi", "i2c", "dma", "asm", "mcu",
                  "arm", "plc", "ihm", "uml", "aws", "gcp", "k8s", "c#", "c++"}


def fold(text: str) -> str:
    """Minuscules sans accents — même normalisation que le front (fold en JS)."""
    if not text:
        return ""
    return "".join(
        ch for ch in unicodedata.normalize("NFD", str(text).lower())
        if unicodedata.category(ch) != "Mn"
    )


def _build_pattern() -> tuple[re.Pattern, dict[str, str]]:
    """Une seule regex alternative pour tout le vocabulaire : un balayage par
    texte, quel que soit le nombre de compétences suivies."""
    alias_to_canon: dict[str, str] = {}
    parts: list[str] = []
    # Les alias les plus longs d'abord : « linux embarque » doit gagner sur « linux »
    for canon, aliases in _SKILLS.items():
        for alias in aliases:
            alias_to_canon[alias] = canon
    for alias in sorted(alias_to_canon, key=len, reverse=True):
        esc = re.escape(alias)
        # Frontière gauche : début ou caractère non alphanumérique.
        # Frontière droite : les alias finissant par + ou # (c++, c#) ne peuvent
        # pas utiliser \b (le + n'est pas un caractère de mot) — on exige alors
        # simplement de ne pas être suivi d'un caractère de mot.
        if alias[-1].isalnum():
            parts.append(rf"(?<![\w+#]){esc}(?![\w+#])")
        else:
            parts.append(rf"(?<![\w+#]){esc}(?![\w])")
    return re.compile("|".join(parts)), alias_to_canon


_PATTERN, _ALIAS_TO_CANON = _build_pattern()


def extract_skills(text: str) -> set[str]:
    """Compétences (noms canoniques) mentionnées dans un texte libre."""
    folded = fold(text)
    if not folded:
        return set()
    found: set[str] = set()
    for m in _PATTERN.finditer(folded):
        canon = _ALIAS_TO_CANON.get(m.group(0))
        if canon:
            found.add(canon)
    return found


# Nombre maximal d'offres analysées : borne le coût quel que soit l'historique.
MAX_OFFERS_ANALYSED = 800


def analyse(offer_texts: list[str], cv_text: str, top: int = 25) -> dict:
    """Compare la demande du marché (offres) à l'offre du candidat (CV).

    Retourne :
      - `skills` : compétences les plus demandées, avec le nombre d'offres qui
        les citent, leur part en pourcentage, et si le CV les mentionne ;
      - `missing` : celles qui manquent au CV, les plus demandées d'abord ;
      - `strengths` : celles du CV réellement demandées par le marché.
    """
    texts = offer_texts[:MAX_OFFERS_ANALYSED]
    total = len(texts)
    demand: Counter[str] = Counter()
    for t in texts:
        # set() par offre : une compétence citée 5 fois dans la même annonce
        # compte pour UNE offre, pas cinq — on mesure la diffusion, pas le bavardage.
        for skill in extract_skills(t):
            demand[skill] += 1

    cv_skills = extract_skills(cv_text)
    ranked = demand.most_common(top)
    skills = [
        {
            "name": name,
            "count": count,
            "pct": round(100.0 * count / total) if total else 0,
            "in_cv": name in cv_skills,
        }
        for name, count in ranked
    ]
    missing = [s for s in skills if not s["in_cv"]]
    strengths = [s for s in skills if s["in_cv"]]
    return {
        "analysed_offers": total,
        "truncated": len(offer_texts) > MAX_OFFERS_ANALYSED,
        "cv_known": bool(cv_skills),
        "skills": skills,
        "missing": missing,
        "strengths": strengths,
    }
