"""
Détection des serveurs LLM locaux (Ollama, LM Studio, llama.cpp) et de la
puissance machine (RAM/VRAM) pour suggérer un modèle adapté.

Tout est code pur + requêtes HTTP locales courtes (timeout 2 s) : aucune
dépendance supplémentaire, aucun appel réseau externe.
"""
import json
import os
import re
import subprocess
import urllib.parse
import urllib.request

from config import config

_TIMEOUT = 2.0  # serveurs locaux : réponse immédiate ou absent

# Ports par défaut des serveurs locaux usuels
_LMSTUDIO_URL = "http://localhost:1234/v1/models"
_LLAMACPP_URL = "http://localhost:8080/v1/models"


def _get_json(url: str) -> dict | list | None:
    """GET JSON court vers un serveur LLM (Ollama/LM Studio/llama.cpp), None si
    absent. N'autorise que les schémas http(s) : aucun file://, gopher://… ne
    peut être sondé même si OLLAMA_BASE_URL était mal configuré."""
    try:
        if urllib.parse.urlparse(url).scheme not in ("http", "https"):
            return None
        req = urllib.request.Request(url, headers={"Accept": "application/json"})
        with urllib.request.urlopen(req, timeout=_TIMEOUT) as resp:  # noqa: S310 (http(s) only)
            return json.loads(resp.read(1_000_000).decode("utf-8", "replace"))
    except Exception:
        return None


def probe_ollama() -> dict | None:
    """Modèles installés sur le serveur Ollama configuré (OLLAMA_BASE_URL)."""
    base = (config.ollama_base_url or "http://localhost:11434").rstrip("/")
    data = _get_json(f"{base}/api/tags")
    if not isinstance(data, dict):
        return None
    models = []
    for m in data.get("models", []) or []:
        if isinstance(m, dict) and m.get("name"):
            size_gb = round(int(m.get("size", 0)) / 1e9, 1) if m.get("size") else None
            models.append({"name": str(m["name"])[:80], "size_gb": size_gb})
    return {"server": "Ollama", "url": base, "models": models[:50]}


def _probe_openai_compatible(server: str, url: str) -> dict | None:
    """LM Studio et llama.cpp exposent l'API OpenAI /v1/models."""
    data = _get_json(url)
    if not isinstance(data, dict) or not isinstance(data.get("data"), list):
        return None
    models = [
        {"name": str(m.get("id", ""))[:120], "size_gb": None}
        for m in data["data"] if isinstance(m, dict) and m.get("id")
    ]
    return {"server": server, "url": url.rsplit("/v1/", 1)[0], "models": models[:50]}


def detect_servers() -> list[dict]:
    """Serveurs LLM locaux actifs avec leurs modèles."""
    found = []
    for probe in (
        probe_ollama,
        lambda: _probe_openai_compatible("LM Studio", _LMSTUDIO_URL),
        lambda: _probe_openai_compatible("llama.cpp", _LLAMACPP_URL),
    ):
        result = probe()
        if result:
            found.append(result)
    return found


# ─── Puissance machine ────────────────────────────────────────────────────────

def total_ram_gb() -> float | None:
    """RAM totale en Go — /proc/meminfo (Linux) ou sysconf (macOS/BSD)."""
    try:
        with open("/proc/meminfo", encoding="ascii") as f:
            match = re.search(r"MemTotal:\s+(\d+)\s*kB", f.read())
        if match:
            return round(int(match.group(1)) / 1024 / 1024, 1)
    except OSError:
        pass
    try:
        pages = os.sysconf("SC_PHYS_PAGES")
        page_size = os.sysconf("SC_PAGE_SIZE")
        return round(pages * page_size / 1e9, 1)
    except (ValueError, OSError, AttributeError):
        return None


def total_vram_gb() -> float | None:
    """VRAM du premier GPU NVIDIA via nvidia-smi, None si absent."""
    try:
        out = subprocess.run(
            ["nvidia-smi", "--query-gpu=memory.total", "--format=csv,noheader,nounits"],
            capture_output=True, text=True, timeout=5,
        )
        if out.returncode == 0 and out.stdout.strip():
            first = out.stdout.strip().splitlines()[0]
            return round(float(first) / 1024, 1)
    except (OSError, ValueError, subprocess.TimeoutExpired):
        pass
    return None


def suggest_models(ram_gb: float | None, vram_gb: float | None) -> list[dict]:
    """Modèles locaux conseillés selon la mémoire disponible. Le facteur
    limitant est la VRAM si un GPU est présent, sinon la RAM (inférence CPU)."""
    budget = vram_gb if vram_gb else ram_gb
    if budget is None:
        return [{"model": "llama3.2", "reason": "défaut raisonnable (mémoire inconnue)"}]
    tiers = [
        (24, [("mixtral", "8x7B : qualité proche des modèles cloud"),
              ("qwen2.5:32b", "excellent en français, exigeant en mémoire")]),
        (12, [("mistral-small", "bon équilibre qualité/vitesse"),
              ("qwen2.5:14b", "très bon multilingue")]),
        (6,  [("mistral:7b", "le classique 7B, robuste"),
              ("llama3.2", "3B rapide, suffisant pour le pré-scoring")]),
        (0,  [("llama3.2:1b", "1B ultra-léger"),
              ("tinyllama", "minimal — qualité limitée pour les lettres")]),
    ]
    for threshold, models in tiers:
        if budget >= threshold:
            return [{"model": m, "reason": r} for m, r in models]
    return []


def scan() -> dict:
    """Bilan complet : serveurs actifs, modèles installés, matériel, conseils."""
    ram = total_ram_gb()
    vram = total_vram_gb()
    return {
        "servers": detect_servers(),
        "ram_gb": ram,
        "vram_gb": vram,
        "suggestions": suggest_models(ram, vram),
    }
