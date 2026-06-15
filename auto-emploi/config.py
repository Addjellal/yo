import os
import re
import tempfile
import threading
import urllib.parse
from dataclasses import dataclass, field
from pathlib import Path

from dotenv import load_dotenv

# Le .env et output/ vivent dans le dossier du projet, pas dans le cwd :
# l'application fonctionne quel que soit le dossier d'où elle est lancée.
_PROJECT_DIR = Path(__file__).resolve().parent
load_dotenv(_PROJECT_DIR / ".env")


def _env_choice(name: str, default: str, allowed: tuple[str, ...]) -> str:
    """Valeur d'environnement restreinte à une liste blanche."""
    value = os.getenv(name, default).strip().lower()
    return value if value in allowed else default


def _env_url(name: str, default: str) -> str:
    """URL d'environnement : seuls http(s) avec hôte sont acceptés (anti-SSRF)."""
    value = os.getenv(name, default).strip().rstrip("/")
    try:
        parsed = urllib.parse.urlparse(value)
    except ValueError:
        return default
    if parsed.scheme not in ("http", "https") or not parsed.netloc:
        return default
    return value


_MODEL_RE = re.compile(r"^[A-Za-z0-9._:-]{1,100}$")


def _env_model(name: str, default: str) -> str:
    """Nom de modèle : caractères sûrs uniquement (part dans des en-têtes HTTP)."""
    value = os.getenv(name, default).strip()
    return value if _MODEL_RE.match(value) else default


def _env_int(name: str, default: int, lo: int, hi: int) -> int:
    """Lecture sécurisée d'un entier d'environnement (borné, jamais de crash)."""
    try:
        value = int(os.getenv(name, str(default)))
    except (TypeError, ValueError):
        return default
    return max(lo, min(hi, value))


def _env_float(name: str, default: float, lo: float, hi: float) -> float:
    try:
        value = float(os.getenv(name, str(default)))
    except (TypeError, ValueError):
        return default
    return max(lo, min(hi, value))


@dataclass
class Config:
    # IA provider : "anthropic" ou "ollama" (toute autre valeur → anthropic)
    provider: str = field(default_factory=lambda: _env_choice("PROVIDER", "anthropic", ("anthropic", "ollama")))

    # Anthropic (requis si provider=anthropic)
    anthropic_api_key: str = field(default_factory=lambda: os.getenv("ANTHROPIC_API_KEY", "").strip())
    # Claude Fable 5 : modèle le plus capable (JSON structuré garanti, vision haute résolution)
    anthropic_model: str = field(default_factory=lambda: _env_model("ANTHROPIC_MODEL", "claude-fable-5"))

    # Ollama (requis si provider=ollama)
    ollama_base_url: str = field(default_factory=lambda: _env_url("OLLAMA_BASE_URL", "http://localhost:11434"))
    ollama_model: str = field(default_factory=lambda: _env_model("OLLAMA_MODEL", "llama3.2"))
    ollama_vision_model: str = field(default_factory=lambda: _env_model("OLLAMA_VISION_MODEL", "llava"))

    # Sources
    france_travail_client_id: str = field(default_factory=lambda: os.getenv("FRANCE_TRAVAIL_CLIENT_ID", ""))
    france_travail_client_secret: str = field(default_factory=lambda: os.getenv("FRANCE_TRAVAIL_CLIENT_SECRET", ""))
    linkedin_email: str = field(default_factory=lambda: os.getenv("LINKEDIN_EMAIL", ""))
    linkedin_password: str = field(default_factory=lambda: os.getenv("LINKEDIN_PASSWORD", ""))
    adzuna_app_id: str = field(default_factory=lambda: os.getenv("ADZUNA_APP_ID", ""))
    adzuna_app_key: str = field(default_factory=lambda: os.getenv("ADZUNA_APP_KEY", ""))

    # Notion (optionnel : export des offres retenues vers une base Notion)
    notion_token: str = field(default_factory=lambda: os.getenv("NOTION_TOKEN", "").strip())
    notion_database_id: str = field(default_factory=lambda: os.getenv("NOTION_DATABASE_ID", "").strip())

    # Mots-clés éliminatoires (séparés par virgule) : offres écartées avant l'IA
    exclude_keywords: str = field(default_factory=lambda: os.getenv("EXCLUDE_KEYWORDS", "").strip())

    # Coordonnées du candidat : en-tête des lettres de motivation (PDF + TXT)
    candidate_name: str = field(default_factory=lambda: os.getenv("CANDIDATE_NAME", "").strip()[:80])
    candidate_email: str = field(default_factory=lambda: os.getenv("CANDIDATE_EMAIL", "").strip()[:120])
    candidate_phone: str = field(default_factory=lambda: os.getenv("CANDIDATE_PHONE", "").strip()[:40])
    candidate_city: str = field(default_factory=lambda: os.getenv("CANDIDATE_CITY", "").strip()[:80])

    # Routage IA par tâche : "" = suivre PROVIDER, sinon "local" (Ollama) ou
    # "claude" (API Anthropic). Modèle vide = modèle par défaut du backend.
    ai_prescore_backend: str = field(default_factory=lambda: _env_choice("AI_PRESCORE_BACKEND", "", ("", "local", "claude")))
    ai_match_backend: str = field(default_factory=lambda: _env_choice("AI_MATCH_BACKEND", "", ("", "local", "claude")))
    ai_letter_backend: str = field(default_factory=lambda: _env_choice("AI_LETTER_BACKEND", "", ("", "local", "claude")))
    ai_review_backend: str = field(default_factory=lambda: _env_choice("AI_REVIEW_BACKEND", "", ("", "local", "claude")))
    ai_prescore_model: str = field(default_factory=lambda: _env_model("AI_PRESCORE_MODEL", ""))
    ai_match_model: str = field(default_factory=lambda: _env_model("AI_MATCH_MODEL", ""))
    ai_letter_model: str = field(default_factory=lambda: _env_model("AI_LETTER_MODEL", ""))
    ai_review_model: str = field(default_factory=lambda: _env_model("AI_REVIEW_MODEL", ""))
    # Si le backend d'une tâche échoue : "none" = erreur claire, sinon bascule
    ai_fallback: str = field(default_factory=lambda: _env_choice("AI_FALLBACK", "none", ("none", "local", "claude")))

    # Lettres : réutiliser les lettres précédentes comme exemples de style (few-shot)
    letter_examples: str = field(default_factory=lambda: _env_choice("LETTER_EXAMPLES", "off", ("off", "on")))
    # Lettres : passe de relecture IA après génération (cohérence CV/offre, français)
    letter_review: str = field(default_factory=lambda: _env_choice("LETTER_REVIEW", "off", ("off", "on")))

    # Derniers critères choisis (persistés pour les reproposer au prochain lancement)
    default_sources: str = field(default_factory=lambda: os.getenv("DEFAULT_SOURCES", "").strip()[:200])
    default_sectors: str = field(default_factory=lambda: os.getenv("DEFAULT_SECTORS", "").strip()[:400])
    default_location: str = field(default_factory=lambda: os.getenv("DEFAULT_LOCATION", "").strip()[:120])
    default_country: str = field(default_factory=lambda: os.getenv("DEFAULT_COUNTRY", "fr").strip().lower()[:2] or "fr")
    default_experience: str = field(default_factory=lambda: os.getenv("DEFAULT_EXPERIENCE", "").strip()[:20])

    # Pays courant (code ISO, défini par le sélecteur de localisation au runtime)
    country: str = "fr"

    # Paramètres (bornés pour éviter les valeurs absurdes ou hostiles)
    output_dir: str = field(default_factory=lambda: os.getenv("OUTPUT_DIR", str(_PROJECT_DIR / "output")))
    max_jobs_per_source: int = field(default_factory=lambda: _env_int("MAX_JOBS_PER_SOURCE", 50, 1, 200))
    min_match_score: int = field(default_factory=lambda: _env_int("MIN_MATCH_SCORE", 6, 0, 10))
    request_delay: float = field(default_factory=lambda: _env_float("REQUEST_DELAY", 2.0, 0.0, 30.0))
    # Multi-CV : nombre d'offres gardées par le pré-filtre commun avant l'analyse
    # détaillée par CV (au-delà, un pré-scoring unique sur le profil fusionné trie).
    multi_cv_shared_keep: int = field(default_factory=lambda: _env_int("MULTI_CV_SHARED_KEEP", 150, 20, 1000))
    # Délai max (secondes) d'un appel LLM avant abandon, pour les tâches
    # interactives (lettres, relecture) — évite qu'un serveur Ollama bloqué fige
    # une génération. 0 = aucun plafond. Les analyses (pré-scoring + analyse
    # détaillée) n'ont jamais de plafond : elles vont toujours au bout.
    llm_timeout: int = field(default_factory=lambda: _env_int("LLM_TIMEOUT", 120, 0, 600))


config = Config()

# Clés autorisées à être persistées dans .env via save_to_env
_ALLOWED_ENV_KEYS = {
    "PROVIDER", "ANTHROPIC_API_KEY", "ANTHROPIC_MODEL",
    "OLLAMA_BASE_URL", "OLLAMA_MODEL", "OLLAMA_VISION_MODEL",
    "FRANCE_TRAVAIL_CLIENT_ID", "FRANCE_TRAVAIL_CLIENT_SECRET",
    "LINKEDIN_EMAIL", "LINKEDIN_PASSWORD",
    "ADZUNA_APP_ID", "ADZUNA_APP_KEY",
    "NOTION_TOKEN", "NOTION_DATABASE_ID",
    "OUTPUT_DIR", "MAX_JOBS_PER_SOURCE", "MIN_MATCH_SCORE", "REQUEST_DELAY",
    "MULTI_CV_SHARED_KEEP", "LLM_TIMEOUT",
    "EXCLUDE_KEYWORDS",
    "CANDIDATE_NAME", "CANDIDATE_EMAIL", "CANDIDATE_PHONE", "CANDIDATE_CITY",
    "AI_PRESCORE_BACKEND", "AI_MATCH_BACKEND", "AI_LETTER_BACKEND", "AI_REVIEW_BACKEND",
    "AI_PRESCORE_MODEL", "AI_MATCH_MODEL", "AI_LETTER_MODEL", "AI_REVIEW_MODEL", "AI_FALLBACK",
    "LETTER_EXAMPLES", "LETTER_REVIEW",
    "DEFAULT_SOURCES", "DEFAULT_SECTORS", "DEFAULT_LOCATION",
    "DEFAULT_COUNTRY", "DEFAULT_EXPERIENCE",
}
_KEY_RE = re.compile(r"^[A-Z][A-Z0-9_]*$")
# Clés numériques : on recoerce le type avant de l'écrire dans l'objet config,
# sinon une valeur saisie dans l'UI web y resterait en chaîne (« 120 »).
_NUMERIC_ENV_KEYS = {
    "MAX_JOBS_PER_SOURCE": int, "MIN_MATCH_SCORE": int, "REQUEST_DELAY": float,
    "MULTI_CV_SHARED_KEEP": int, "LLM_TIMEOUT": int,
}
# Clés dont la valeur est un nom de modèle : validées contre _MODEL_RE (mêmes
# caractères qu'au chargement) pour ne pas persister une valeur ingérable.
_MODEL_VALUE_KEYS = {
    "ANTHROPIC_MODEL", "OLLAMA_MODEL", "OLLAMA_VISION_MODEL",
    "AI_PRESCORE_MODEL", "AI_MATCH_MODEL", "AI_LETTER_MODEL", "AI_REVIEW_MODEL",
}

# Sérialise les écritures de .env : un auto-save de modèle (thread de scan) et
# une sauvegarde des réglages (thread de requête) peuvent survenir en parallèle.
# Sans verrou, le read-modify-write pourrait perdre une mise à jour.
_ENV_LOCK = threading.Lock()


def save_to_env(key: str, value: str) -> None:
    """Persiste key=value dans .env, en refusant toute clé inconnue et toute
    valeur contenant un retour à la ligne (empêche l'injection de variables).
    Écriture atomique avec permissions restrictives dès la création."""
    key = key.strip().upper()
    if key not in _ALLOWED_ENV_KEYS or not _KEY_RE.match(key):
        raise ValueError(f"Clé non autorisée dans .env : {key!r}")
    # Une valeur multi-lignes pourrait injecter d'autres variables : on neutralise.
    value = str(value).replace("\r", " ").replace("\n", " ").strip()[:2000]

    # Pour une clé numérique, on valide AVANT toute écriture : un cast invalide
    # rejette la sauvegarde plutôt que de laisser une valeur corrompue dans .env.
    caster = _NUMERIC_ENV_KEYS.get(key)
    typed: object = value
    if caster is not None:
        try:
            typed = caster(value)
        except (TypeError, ValueError):
            raise ValueError(f"Valeur numérique invalide pour {key} : {value!r}")

    # Nom de modèle : on rejette une valeur invalide AVANT d'écrire, sinon elle
    # serait silencieusement ignorée au prochain chargement (_env_model) et
    # remplacée par le défaut — comportement déroutant. Une valeur vide reste
    # permise (AI_*_MODEL vide = suivre le modèle par défaut du backend).
    if key in _MODEL_VALUE_KEYS and value and not _MODEL_RE.match(value):
        raise ValueError(f"Nom de modèle invalide pour {key} : {value!r}")

    env_path = _PROJECT_DIR / ".env"
    # Verrou : read-modify-write atomique vis-à-vis des autres threads.
    with _ENV_LOCK:
        lines = env_path.read_text(encoding="utf-8").splitlines() if env_path.exists() else []
        updated = False
        for i, line in enumerate(lines):
            if line.startswith(f"{key}=") or line.startswith(f"{key} ="):
                lines[i] = f"{key}={value}"
                updated = True
                break
        if not updated:
            lines.append(f"{key}={value}")

        # mkstemp crée le fichier en 0600 : les secrets ne sont jamais lisibles par
        # d'autres comptes, même pendant l'écriture. os.replace = pas de .env tronqué.
        fd, tmp_name = tempfile.mkstemp(dir=str(env_path.resolve().parent), prefix=".env_", suffix=".tmp")
        try:
            with os.fdopen(fd, "w", encoding="utf-8") as f:
                f.write("\n".join(lines) + "\n")
            os.replace(tmp_name, env_path)
        except OSError:
            try:
                os.unlink(tmp_name)
            except OSError:
                pass
            raise

    # Stocke le bon type dans l'objet config (déjà validé plus haut pour les
    # champs numériques : ils ne restent jamais en chaîne après une sauvegarde).
    setattr(config, key.lower(), typed)
