import os
import re
import tempfile
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

    # Pays courant (code ISO, défini par le sélecteur de localisation au runtime)
    country: str = "fr"

    # Paramètres (bornés pour éviter les valeurs absurdes ou hostiles)
    output_dir: str = field(default_factory=lambda: os.getenv("OUTPUT_DIR", str(_PROJECT_DIR / "output")))
    max_jobs_per_source: int = field(default_factory=lambda: _env_int("MAX_JOBS_PER_SOURCE", 50, 1, 200))
    min_match_score: int = field(default_factory=lambda: _env_int("MIN_MATCH_SCORE", 6, 0, 10))
    request_delay: float = field(default_factory=lambda: _env_float("REQUEST_DELAY", 2.0, 0.0, 30.0))


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
    "EXCLUDE_KEYWORDS",
}
_KEY_RE = re.compile(r"^[A-Z][A-Z0-9_]*$")


def save_to_env(key: str, value: str) -> None:
    """Persiste key=value dans .env, en refusant toute clé inconnue et toute
    valeur contenant un retour à la ligne (empêche l'injection de variables).
    Écriture atomique avec permissions restrictives dès la création."""
    key = key.strip().upper()
    if key not in _ALLOWED_ENV_KEYS or not _KEY_RE.match(key):
        raise ValueError(f"Clé non autorisée dans .env : {key!r}")
    # Une valeur multi-lignes pourrait injecter d'autres variables : on neutralise.
    value = str(value).replace("\r", " ").replace("\n", " ").strip()[:2000]

    env_path = _PROJECT_DIR / ".env"
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

    setattr(config, key.lower(), value)
