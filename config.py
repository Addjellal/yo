from dataclasses import dataclass, field
from dotenv import load_dotenv
from pathlib import Path
import os

load_dotenv()


@dataclass
class Config:
    anthropic_api_key: str = field(default_factory=lambda: os.getenv("ANTHROPIC_API_KEY", ""))
    france_travail_client_id: str = field(default_factory=lambda: os.getenv("FRANCE_TRAVAIL_CLIENT_ID", ""))
    france_travail_client_secret: str = field(default_factory=lambda: os.getenv("FRANCE_TRAVAIL_CLIENT_SECRET", ""))
    linkedin_email: str = field(default_factory=lambda: os.getenv("LINKEDIN_EMAIL", ""))
    linkedin_password: str = field(default_factory=lambda: os.getenv("LINKEDIN_PASSWORD", ""))
    output_dir: str = field(default_factory=lambda: os.getenv("OUTPUT_DIR", "output"))
    max_jobs_per_source: int = field(default_factory=lambda: int(os.getenv("MAX_JOBS_PER_SOURCE", "50")))
    min_match_score: int = field(default_factory=lambda: int(os.getenv("MIN_MATCH_SCORE", "6")))
    request_delay: float = field(default_factory=lambda: float(os.getenv("REQUEST_DELAY", "2.0")))


config = Config()


def save_to_env(key: str, value: str) -> None:
    """Persist a new key=value line into .env (creates file if absent)."""
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
    # Reflect in the live config object too
    setattr(config, key.lower(), value)
