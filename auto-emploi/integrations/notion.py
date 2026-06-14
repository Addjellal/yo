"""
Export des offres retenues vers une base de données Notion (optionnel).

Configuration (.env) :
    NOTION_TOKEN=secret_...        # https://www.notion.so/my-integrations
    NOTION_DATABASE_ID=...         # ID de la base (32 caractères de l'URL)

La base Notion doit avoir ces propriétés (créées en 1 min) :
    Poste (Title) · Entreprise (Text) · Lieu (Text) · Score (Number)
    Source (Text) · URL (URL)
N'oubliez pas de partager la base avec votre intégration (menu ··· → Connexions).
"""
import re

import requests
from rich.markup import escape

from config import config
from app_utils import console

_API = "https://api.notion.com/v1/pages"
_VERSION = "2022-06-28"
_DB_ID_RE = re.compile(r"^[a-f0-9-]{32,36}$")
# Formats de jeton Notion (secret_… historique, ntn_… actuel) + en-tête Bearer,
# masqués indépendamment du token configuré : même un secret tiers ne fuite pas.
_SECRET_RE = re.compile(r"(?:secret_|ntn_)[A-Za-z0-9]{8,}|Bearer\s+\S+", re.I)


def notion_configured() -> bool:
    return bool(config.notion_token and config.notion_database_id)


def _redact(message) -> str:
    """Jamais de jeton Notion dans la console : on masque le token configuré
    (s'il apparaît verbatim) ET tout motif de secret/en-tête Bearer."""
    text = str(message)
    token = config.notion_token
    if token:
        text = text.replace(token, "***")
    return _SECRET_RE.sub("***", text)


def export_to_notion(offers) -> int:
    """Crée une page Notion par offre. Retourne le nombre exporté."""
    if not notion_configured():
        return 0
    db_id = config.notion_database_id.strip()
    if not _DB_ID_RE.match(db_id):
        console.print("[yellow][Notion] NOTION_DATABASE_ID invalide (attendu : 32 caractères hexadécimaux).[/yellow]")
        return 0

    headers = {
        "Authorization": f"Bearer {config.notion_token}",
        "Notion-Version": _VERSION,
        "Content-Type": "application/json",
    }
    exported = 0
    for offer in offers:
        properties = {
            "Poste": {"title": [{"text": {"content": offer.title[:200]}}]},
            "Entreprise": {"rich_text": [{"text": {"content": offer.company[:200]}}]},
            "Lieu": {"rich_text": [{"text": {"content": (offer.location or "")[:200]}}]},
            "Score": {"number": offer.match_score or 0},
            "Source": {"rich_text": [{"text": {"content": offer.source[:60]}}]},
        }
        if offer.url:
            properties["URL"] = {"url": offer.url}
        try:
            resp = requests.post(
                _API,
                headers=headers,
                json={"parent": {"database_id": db_id}, "properties": properties},
                timeout=10,
            )
            if resp.status_code == 200:
                exported += 1
            else:
                detail = resp.json().get("message", resp.status_code) if resp.headers.get("content-type", "").startswith("application/json") else resp.status_code
                console.print(f"[yellow][Notion] Échec pour « {escape(offer.title[:40])} » : {escape(_redact(detail))}[/yellow]")
                if resp.status_code in (401, 403, 404):
                    break  # config invalide : inutile d'insister sur les suivantes
        except requests.RequestException as e:
            console.print(f"[yellow][Notion] Erreur réseau : {escape(_redact(e))}[/yellow]")
            break
    if exported:
        console.print(f"[green]✓ {exported} offre(s) exportée(s) vers Notion[/green]")
    return exported
