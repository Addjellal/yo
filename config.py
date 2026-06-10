import os
import re
import stat
import sys
from dataclasses import dataclass, field
from pathlib import Path

from dotenv import load_dotenv

load_dotenv()


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
    # IA provider : "anthropic" ou "ollama"
    provider: str = field(default_factory=lambda: os.getenv("PROVIDER", "anthropic").strip().lower())

    # Anthropic (requis si provider=anthropic)
    anthropic_api_key: str = field(default_factory=lambda: os.getenv("ANTHROPIC_API_KEY", ""))
    # Claude Fable 5 : modèle le plus capable (JSON structuré garanti, vision haute résolution)
    anthropic_model: str = field(default_factory=lambda: os.getenv("ANTHROPIC_MODEL", "claude-fable-5"))

    # Ollama (requis si provider=ollama)
    ollama_base_url: str = field(default_factory=lambda: os.getenv("OLLAMA_BASE_URL", "http://localhost:11434"))
    ollama_model: str = field(default_factory=lambda: os.getenv("OLLAMA_MODEL", "llama3.2"))
    ollama_vision_model: str = field(default_factory=lambda: os.getenv("OLLAMA_VISION_MODEL", "llava"))

    # Sources
    france_travail_client_id: str = field(default_factory=lambda: os.getenv("FRANCE_TRAVAIL_CLIENT_ID", ""))
    france_travail_client_secret: str = field(default_factory=lambda: os.getenv("FRANCE_TRAVAIL_CLIENT_SECRET", ""))
    linkedin_email: str = field(default_factory=lambda: os.getenv("LINKEDIN_EMAIL", ""))
    linkedin_password: str = field(default_factory=lambda: os.getenv("LINKEDIN_PASSWORD", ""))
    adzuna_app_id: str = field(default_factory=lambda: os.getenv("ADZUNA_APP_ID", ""))
    adzuna_app_key: str = field(default_factory=lambda: os.getenv("ADZUNA_APP_KEY", ""))

    # Paramètres (bornés pour éviter les valeurs absurdes ou hostiles)
    output_dir: str = field(default_factory=lambda: os.getenv("OUTPUT_DIR", "output"))
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
    "OUTPUT_DIR", "MAX_JOBS_PER_SOURCE", "MIN_MATCH_SCORE", "REQUEST_DELAY",
}
_KEY_RE = re.compile(r"^[A-Z][A-Z0-9_]*$")


def save_to_env(key: str, value: str) -> None:
    """Persiste key=value dans .env, en refusant toute clé inconnue et toute
    valeur contenant un retour à la ligne (empêche l'injection de variables)."""
    key = key.strip().upper()
    if key not in _ALLOWED_ENV_KEYS or not _KEY_RE.match(key):
        raise ValueError(f"Clé non autorisée dans .env : {key!r}")
    # Une valeur multi-lignes pourrait injecter d'autres variables : on neutralise.
    value = str(value).replace("\r", " ").replace("\n", " ").strip()

    env_path = Path(".env")
    lines = env_path.read_text(encoding="utf-8").splitlines() if env_path.exists() else []
    updated = False
    for i, line in enumerate(lines):
        if line.startswith(f"{key}=") or line.startswith(f"{key} ="):
            lines[i] = f"{key}={value}"
            updated = True
            break
    if not updated:
        lines.append(f"{key}={value}")
    env_path.write_text("\n".join(lines) + "\n", encoding="utf-8")

    # .env contient des secrets : lecture/écriture par le propriétaire uniquement (POSIX)
    if sys.platform != "win32":
        try:
            env_path.chmod(stat.S_IRUSR | stat.S_IWUSR)
        except OSError:
            pass

    setattr(config, key.lower(), value)
