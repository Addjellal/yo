#!/usr/bin/env python3
"""
Auto Job Application – recherche, matching IA et génération de lettres de motivation.

Usage rapide :
    python main.py --check                          # Vérifier l'environnement
    python main.py --cv cv.pdf --scan               # Scanner sans postuler
    python main.py --cv cv.pdf --query "dev Python" # Mode complet
"""
# Garantit que le dossier du projet est résolu en premier,
# avant les packages tiers installés dans site-packages.
import sys as _sys
import os as _os
_sys.path.insert(0, _os.path.dirname(_os.path.abspath(__file__)))
del _sys, _os

import argparse
import csv
import importlib.util
import json
import sys
import time
import urllib.parse
import webbrowser
from concurrent.futures import ThreadPoolExecutor, as_completed
from pathlib import Path

from rich.console import Console
from rich.markup import escape
from rich.panel import Panel
from rich.progress import Progress, SpinnerColumn, TextColumn
from rich.prompt import Confirm, Prompt
from rich.table import Table
from rich import box

from config import config, save_to_env
from cv_parser import parse_cv
from job_scrapers import (
    JobOffer,
    FranceTravailScraper,
    IndeedScraper,
    WTTJScraper,
    LinkedInScraper,
    ApecScraper,
    AdzunaScraper,
)
from ai import CoverLetterGenerator
from ai.matcher import parse_exclude_keywords, score_offers_multi
from ai.cover_letter import TONES, merge_cv_texts, recent_letter_examples
from tracker import Tracker
from history import SessionStore
from cv_store import CVStore, list_cv_files
from integrations import notion_configured, export_to_notion, desktop_notify
from locations import COUNTRIES, COUNTRY_NAMES, FR_REGIONS, search_names, _fold

# Plafond du pré-filtre code pur avant le re-scoring IA de toute la base
RESCORE_TOP_K = 150

# Dossier du projet : les CV uploadés via le web y vivent, le registre les référence
_PROJECT_DIR = Path(__file__).resolve().parent

console = Console()

# Marqueurs visuels pour les statuts de tracking
STATUS_BADGE = {
    "new":      "",
    "seen":     "[dim]·[/dim]",
    "favorite": "[yellow]★[/yellow]",
    "applied":  "[green]✓[/green]",
    "rejected": "[red]✗[/red]",
}

EXPERIENCE_LEVELS: list[tuple[str, str]] = [
    ("stage",    "Stage / Alternance"),
    ("junior",   "Junior (0–2 ans)"),
    ("confirme", "Confirmé (2–5 ans)"),
    ("senior",   "Senior (5–10 ans)"),
    ("expert",   "Expert (10+ ans)"),
]

_SESSION_STORE: SessionStore | None = None
_CV_STORE: CVStore | None = None


def _get_store() -> SessionStore:
    global _SESSION_STORE
    if _SESSION_STORE is None:
        _SESSION_STORE = SessionStore(Path(config.output_dir) / ".sessions.json")
    return _SESSION_STORE


def _get_cv_store() -> CVStore:
    global _CV_STORE
    if _CV_STORE is None:
        _CV_STORE = CVStore(Path(config.output_dir) / ".cvs.json")
    return _CV_STORE


def _load_cv_texts(paths: list[str]) -> dict[str, str]:
    """Parse chaque CV, l'enregistre dans le registre et retourne
    {label → texte effectif} (corrections manuelles incluses, prioritaires).
    Lève FileNotFoundError/ValueError comme parse_cv."""
    store = _get_cv_store()
    texts: dict[str, str] = {}
    for path in paths:
        raw = parse_cv(path)
        name = Path(path).name
        entry = store.register(name)
        label = entry.get("label") or name
        if label in texts:  # deux CV avec le même label : le nom de fichier tranche
            label = name
        texts[label] = store.effective_text(entry, raw)
    return texts


def _style_examples() -> dict[str, list[str]] | None:
    """Exemples few-shot depuis les lettres passées, si LETTER_EXAMPLES=on."""
    if config.letter_examples != "on":
        return None
    examples = recent_letter_examples(_get_store())
    return examples if any(examples.values()) else None


def _global_queries(cv_texts: dict[str, str]) -> list[str] | None:
    """Recherche globale : intitulés de poste générés par l'IA depuis les CV.
    None si la génération échoue (message déjà affiché)."""
    from ai.cv_extract import derive_search_queries
    console.print("[bold]Recherche globale :[/bold] génération des requêtes depuis vos CV…")
    try:
        queries = derive_search_queries(merge_cv_texts(cv_texts))
    except Exception as e:
        console.print(f"[red]Génération impossible : {escape(str(e))}[/red] "
                      "[dim]Saisissez une recherche manuellement.[/dim]")
        return None
    console.print("[bold]Requêtes générées :[/bold] " + " · ".join(escape(q) for q in queries))
    return queries


SECTORS: list[tuple[str, str]] = [
    ("tech",       "Informatique / Tech / IA / Cybersécurité"),
    ("finance",    "Finance / Banque / Assurance / Comptabilité"),
    ("marketing",  "Marketing / Communication / Digital / SEO"),
    ("health",     "Santé / Médical / Pharmaceutique / Biotech"),
    ("industry",   "Industrie / Ingénierie / BTP / Mécanique"),
    ("commerce",   "Commerce / Vente / Retail / E-commerce"),
    ("education",  "Éducation / Formation / Recherche"),
    ("legal",      "Juridique / Droit / Compliance"),
    ("hr",         "Ressources Humaines / Recrutement"),
    ("logistics",  "Logistique / Transport / Supply Chain"),
    ("realestate", "Immobilier / Architecture / Construction"),
    ("consulting", "Conseil / Management / Stratégie"),
    ("media",      "Art / Culture / Médias / Audiovisuel / Jeux vidéo"),
    ("energy",     "Énergie / Environnement / Développement durable"),
    ("food",       "Agroalimentaire / Restauration / Hôtellerie"),
    ("public",     "Secteur public / Associations / ONG"),
]

_SECTOR_KEY_BY_LABEL = {label: key for key, label in SECTORS}


def _sector_keys(labels: list[str]) -> list[str]:
    return [_SECTOR_KEY_BY_LABEL[lab] for lab in labels if lab in _SECTOR_KEY_BY_LABEL]


def _safe_open_url(url: str) -> bool:
    """N'ouvre que des URLs http(s) : une offre scrapée pourrait contenir un
    lien file:// ou javascript: malveillant."""
    try:
        scheme = urllib.parse.urlparse(url).scheme.lower()
    except ValueError:
        return False
    if scheme not in ("http", "https"):
        console.print(f"[red]URL bloquée (schéma {scheme!r} non autorisé) : {escape(url[:80])}[/red]")
        return False
    webbrowser.open(url)
    return True


SOURCE_MAP = {
    "ft": ("France Travail", FranceTravailScraper),
    "indeed": ("Indeed", IndeedScraper),
    "wttj": ("Welcome to the Jungle", WTTJScraper),
    "apec": ("Apec", ApecScraper),
    "adzuna": ("Adzuna", AdzunaScraper),
    "linkedin": ("LinkedIn", LinkedInScraper),
}


# ─── Vérification de l'environnement ─────────────────────────────────────────

def _check_ollama() -> tuple[bool, list[str]]:
    """Return (is_running, list_of_pulled_model_names)."""
    try:
        import requests as _req
        r = _req.get(f"{config.ollama_base_url}/api/tags", timeout=3)
        models = [m["name"] for m in r.json().get("models", [])]
        return True, models
    except Exception:
        return False, []


def check_setup() -> None:
    """Affiche un rapport complet de l'environnement et des étapes manquantes."""
    ok = "[bold green]✓[/bold green]"
    ko = "[bold red]✗[/bold red]"
    warn = "[bold yellow]⚠[/bold yellow]"

    lines: list[str] = []

    # Python
    v = sys.version_info
    py_ok = v >= (3, 10)
    lines += [
        "[bold]Python[/bold]",
        f"  {ok if py_ok else ko}  Python {v.major}.{v.minor}.{v.micro}"
        + ("" if py_ok else "  → Requiert Python 3.10+"),
        "",
    ]

    # Provider IA
    provider = config.provider
    lines.append(f"[bold]Provider IA[/bold] : [cyan]{provider}[/cyan]")

    if provider == "ollama":
        ollama_ok, ollama_models = _check_ollama()
        if ollama_ok:
            lines.append(f"  {ok}  Ollama en cours d'exécution sur {config.ollama_base_url}")
            model_pulled = any(config.ollama_model in m for m in ollama_models)
            vision_pulled = any(config.ollama_vision_model in m for m in ollama_models)
            lines.append(
                f"  {ok}  Modèle texte : {config.ollama_model}" if model_pulled
                else f"  {ko}  Modèle texte : {config.ollama_model}  [red]non téléchargé[/red]"
                     f"  → ollama pull {config.ollama_model}"
            )
            lines.append(
                f"  {ok}  Modèle vision : {config.ollama_vision_model}  [dim](OCR PDF)[/dim]" if vision_pulled
                else f"  {warn}  Modèle vision : {config.ollama_vision_model}  [dim]non téléchargé (optionnel pour PDF scannés)[/dim]"
                     f"  → ollama pull {config.ollama_vision_model}"
            )
        else:
            lines.append(f"  {ko}  Ollama [red]non démarré[/red]  → Lancez Ollama puis réessayez")
    else:
        api_key = bool(config.anthropic_api_key)
        lines.append(
            f"  {ok}  ANTHROPIC_API_KEY  [dim]configurée[/dim]" if api_key
            else f"  {ko}  ANTHROPIC_API_KEY  [red]MANQUANTE[/red]  → platform.claude.com"
        )
        lines.append(f"  {ok}  Modèle : [cyan]{config.anthropic_model}[/cyan]")
        ollama_ok = False
    lines.append("")

    # Dépendances
    deps = [
        ("fitz",          "pymupdf",        True,  "Lecture PDF"),
        ("docx",          "python-docx",    True,  "Pour les CV DOCX"),
        ("requests",      "requests",       True,  None),
        ("bs4",           "beautifulsoup4", True,  "Scraping Indeed"),
        ("rich",          "rich",           True,  None),
        ("ollama",        "ollama",         provider == "ollama", "Requis si PROVIDER=ollama"),
        ("anthropic",     "anthropic",      provider == "anthropic", "Requis si PROVIDER=anthropic"),
        ("playwright",    "playwright",     False, "Contournement Cloudflare (Indeed, WTTJ) + LinkedIn — python -m playwright install chromium"),
        ("fpdf",          "fpdf2",          False, "Génération PDF lettres"),
    ]
    lines.append("[bold]Dépendances Python[/bold]")
    for module, pkg, required, note in deps:
        installed = importlib.util.find_spec(module) is not None
        if installed:
            lines.append(f"  {ok}  {pkg}")
        elif required:
            lines.append(f"  {ko}  {pkg}  [red]MANQUANT[/red]  → pip install {pkg}")
        else:
            lines.append(f"  {warn}  {pkg}  [dim]optionnel{' — ' + note if note else ''}[/dim]")
    lines.append("")

    # Sources scraping
    ft_ok = bool(config.france_travail_client_id and config.france_travail_client_secret)
    li_ok = bool(config.linkedin_email and config.linkedin_password)
    playwright_ok = importlib.util.find_spec("playwright") is not None

    adzuna_ok = bool(config.adzuna_app_id and config.adzuna_app_key)

    lines.append("[bold]Sources disponibles[/bold]")
    lines.append(f"  {ok}  Indeed                 [dim](sans configuration — dépend de Cloudflare)[/dim]")
    lines.append(f"  {ok}  Welcome to the Jungle  [dim](sans configuration — dépend de Cloudflare)[/dim]")
    lines.append(f"  {ok}  Apec                   [dim](cadres France, sans configuration)[/dim]")
    lines.append(
        f"  {ok}  Adzuna                 [green]API gratuite configurée[/green]" if adzuna_ok
        else f"  {warn}  Adzuna                 [dim]non configuré — [bold]recommandé[/bold] : developer.adzuna.com (gratuit)[/dim]"
    )
    lines.append(
        f"  {ok}  France Travail" if ft_ok
        else f"  {warn}  France Travail         [dim]non configuré — optionnel[/dim]"
    )
    lines.append(
        f"  {ok}  LinkedIn" if (li_ok and playwright_ok)
        else f"  {warn}  LinkedIn               [dim]désactivé"
             + (" (playwright absent)" if not playwright_ok else " (identifiants manquants)")
             + "[/dim]"
    )
    lines.append("")

    # Verdict
    if provider == "ollama":
        ready = py_ok and ollama_ok
    else:
        ready = py_ok and bool(config.anthropic_api_key)

    if ready:
        lines.append(f"  {ok}  [bold green]Prêt à démarrer ![/bold green]")
    else:
        lines.append(f"  {ko}  [bold red]Configuration incomplète[/bold red] — corrigez les points ci-dessus.")

    console.print(Panel(
        "\n".join(lines),
        title="[bold cyan]Vérification de l'environnement[/bold cyan]",
        border_style="cyan",
        padding=(1, 3),
    ))

    if ready:
        console.print("\n[bold]Prochaines étapes :[/bold]")
        console.print("  [cyan]1.[/cyan] Placez votre CV à la racine du projet")
        console.print("  [cyan]2.[/cyan] Lancez un scan :")
        console.print('     [dim]python main.py --cv votre_cv.pdf --scan[/dim]')
        console.print("  [cyan]3.[/cyan] Ou mode complet avec lettres de motivation :")
        console.print('     [dim]python main.py --cv votre_cv.pdf --query "votre métier" --location "Paris"[/dim]')


# ─── Sélection des secteurs ───────────────────────────────────────────────────

def select_sectors(preselected: str = "") -> list[str]:
    if preselected:
        keys = [s.strip() for s in preselected.split(",")]
        valid = {k for k, _ in SECTORS}
        unknown = [k for k in keys if k not in valid]
        if unknown:
            console.print(f"[yellow]Secteurs inconnus ignorés : {escape(', '.join(unknown))}[/yellow]")
        chosen = [label for k, label in SECTORS if k in keys]
        if chosen:
            console.print(f"[dim]Filtres secteur : {', '.join(chosen)}[/dim]")
        return chosen

    grid = Table.grid(padding=(0, 2))
    grid.add_column(width=4, style="bold cyan")
    grid.add_column(width=38)
    grid.add_column(width=4, style="bold cyan")
    grid.add_column(width=38)

    rows = [(f"{i+1}.", label) for i, (_, label) in enumerate(SECTORS)]
    for left, right in zip(rows[::2], rows[1::2]):
        grid.add_row(left[0], left[1], right[0], right[1])
    if len(rows) % 2:
        last = rows[-1]
        grid.add_row(last[0], last[1], "", "")

    console.print(Panel(
        grid,
        title="[bold cyan]Filtrer par secteur d'activité[/bold cyan]",
        subtitle="[dim]Numéros séparés par virgule, 'all' pour tous, Entrée pour ignorer[/dim]",
        border_style="cyan",
        padding=(1, 2),
    ))

    while True:
        choice = Prompt.ask("[bold cyan]Secteurs[/bold cyan]", default="all").strip().lower()
        if choice in ("", "all", "0"):
            console.print("[dim]Aucun filtre secteur appliqué.[/dim]")
            return []
        if choice == "q":
            sys.exit(0)
        try:
            indices = [int(x.strip()) - 1 for x in choice.split(",")]
            selected = [SECTORS[i][1] for i in indices if 0 <= i < len(SECTORS)]
            if selected:
                console.print(f"[green]Secteurs retenus : {', '.join(selected)}[/green]")
                return selected
            console.print("[red]Numéros hors plage, réessayez.[/red]")
        except ValueError:
            console.print("[red]Format invalide. Exemple : 1,3  ou  all[/red]")


# ─── Sélection du niveau d'expérience ────────────────────────────────────────

def select_experience(preselected: str = "") -> str:
    """Retourne le code niveau ('stage', 'junior', …) ou '' (pas de filtre)."""
    if preselected:
        valid = {k for k, _ in EXPERIENCE_LEVELS}
        if preselected in valid:
            label = next(label for k, label in EXPERIENCE_LEVELS if k == preselected)
            console.print(f"[dim]Filtre expérience : {escape(label)}[/dim]")
            return preselected
        console.print(f"[yellow]Niveau inconnu : {escape(preselected)} — ignoré. Valeurs : {', '.join(k for k, _ in EXPERIENCE_LEVELS)}[/yellow]")
        return ""

    grid = Table.grid(padding=(0, 2))
    grid.add_column(width=4, style="bold cyan")
    grid.add_column(width=32)
    for i, (_, label) in enumerate(EXPERIENCE_LEVELS, 1):
        grid.add_row(f"{i}.", label)

    console.print(Panel(
        grid,
        title="[bold cyan]Niveau d'expérience recherché[/bold cyan]",
        subtitle="[dim]Numéro, 'all' ou Entrée = sans filtre[/dim]",
        border_style="cyan",
        padding=(1, 2),
    ))

    while True:
        choice = Prompt.ask("[bold cyan]Niveau[/bold cyan]", default="all").strip().lower()
        if choice in ("", "all", "0"):
            console.print("[dim]Aucun filtre niveau d'expérience.[/dim]")
            return ""
        if choice == "q":
            sys.exit(0)
        try:
            i = int(choice) - 1
            if 0 <= i < len(EXPERIENCE_LEVELS):
                key, label = EXPERIENCE_LEVELS[i]
                console.print(f"[green]Niveau retenu : {escape(label)}[/green]")
                return key
            console.print(f"[red]Numéro hors plage (1–{len(EXPERIENCE_LEVELS)}).[/red]")
        except ValueError:
            console.print("[red]Format invalide. Entrez un numéro ou 'all'.[/red]")


# ─── Sélection de la localisation ─────────────────────────────────────────────

def _two_column_panel(names: list[str], title: str, subtitle: str) -> None:
    grid = Table.grid(padding=(0, 2))
    grid.add_column(width=4, style="bold cyan")
    grid.add_column(width=32)
    grid.add_column(width=4, style="bold cyan")
    grid.add_column(width=32)
    rows = [(f"{i + 1}.", name) for i, name in enumerate(names)]
    for left, right in zip(rows[::2], rows[1::2]):
        grid.add_row(left[0], left[1], right[0], right[1])
    if len(rows) % 2:
        grid.add_row(rows[-1][0], rows[-1][1], "", "")
    console.print(Panel(grid, title=title, subtitle=subtitle, border_style="cyan", padding=(1, 2)))


def _resolve_choice(raw: str, names: list[str]) -> str | None:
    """Numéro ou recherche par texte (insensible casse/accents).
    Retourne le nom choisi, ou None si ambigu/introuvable."""
    raw = raw.strip()
    if not raw:
        return None
    if raw.isdigit():
        i = int(raw) - 1
        if 0 <= i < len(names):
            return names[i]
        console.print(f"[red]Numéro hors plage (1–{len(names)}).[/red]")
        return None
    exact = [n for n in names if _fold(n) == _fold(raw)]
    if exact:
        return exact[0]
    matches = search_names(raw, names)
    if len(matches) == 1:
        return matches[0]
    if matches:
        console.print(f"[yellow]Plusieurs correspondances : {escape(', '.join(matches[:6]))} — précisez.[/yellow]")
    else:
        console.print("[red]Aucune correspondance, réessayez.[/red]")
    return None


def select_location() -> str:
    """Sélecteur pays → région (France) → ville, avec recherche par texte et
    option 'all' à chaque niveau. Définit config.country et retourne la
    localisation à transmettre aux scrapers ('' = pas de filtre)."""
    # ── Pays ──
    country_names = [name for _, name in COUNTRIES]
    _two_column_panel(
        country_names,
        "[bold cyan]Pays[/bold cyan]",
        "[dim]Numéro, nom à rechercher (ex: 'bel'), 'all' = sans filtre géographique — Entrée = France[/dim]",
    )
    while True:
        raw = Prompt.ask("[bold cyan]Pays[/bold cyan]", default="France").strip()
        if raw.lower() in ("all", "0"):
            config.country = "fr"
            console.print("[dim]Aucun filtre géographique (Apec/France Travail restent centrés France).[/dim]")
            return ""
        chosen = _resolve_choice(raw, country_names)
        if chosen:
            break
    code = next(c for c, n in COUNTRIES if n == chosen)
    config.country = code

    region = ""
    if code == "fr":
        # ── Région (France uniquement) ──
        _two_column_panel(
            FR_REGIONS,
            "[bold cyan]Région[/bold cyan]",
            "[dim]Numéro, nom à rechercher (ex: 'bret'), 'all' ou Entrée = toutes les régions[/dim]",
        )
        while True:
            raw = Prompt.ask("[bold cyan]Région[/bold cyan]", default="all").strip()
            if raw.lower() in ("", "all", "0"):
                break
            picked = _resolve_choice(raw, FR_REGIONS)
            if picked:
                region = picked
                break

    # ── Ville (recherche libre, optionnelle) ──
    city = Prompt.ask(
        "[bold cyan]Ville[/bold cyan] [dim](recherche libre, Entrée pour ignorer)[/dim]",
        default="",
    ).strip()[:80]

    location = city or region
    summary = " › ".join(filter(None, [
        COUNTRY_NAMES[code],
        region or "toutes régions",
        city or "toutes villes",
    ]))
    console.print(f"[green]Localisation : {escape(summary)}[/green]")
    return location


# ─── Sélection interactive des sources ───────────────────────────────────────

def _prompt_france_travail_creds() -> bool:
    """Ask for France Travail API credentials. Returns True if provided."""
    console.print(
        "\n[cyan]France Travail nécessite des identifiants API partenaire (gratuit).[/cyan]\n"
        "[dim]Inscription : https://francetravail.io/produits-et-services/portail-partenaire[/dim]"
    )
    client_id = Prompt.ask("  CLIENT_ID").strip()
    client_secret = Prompt.ask("  CLIENT_SECRET", password=True).strip()
    if not client_id or not client_secret:
        console.print("[yellow]Identifiants vides — France Travail ignoré.[/yellow]")
        return False
    config.france_travail_client_id = client_id
    config.france_travail_client_secret = client_secret
    if Confirm.ask("  Sauvegarder dans .env pour les prochaines sessions ?", default=True):
        save_to_env("FRANCE_TRAVAIL_CLIENT_ID", client_id)
        save_to_env("FRANCE_TRAVAIL_CLIENT_SECRET", client_secret)
        console.print("[dim]Sauvegardé dans .env[/dim]")
    return True


def _prompt_adzuna_creds() -> bool:
    """Ask for Adzuna API credentials. Returns True if provided."""
    console.print(
        "\n[cyan]Adzuna nécessite des clés API (gratuit, sans CB, inscription 2 min).[/cyan]\n"
        "[dim]Inscription : https://developer.adzuna.com[/dim]\n"
        "[dim]Une fois inscrit, récupérez App ID et App Key dans votre tableau de bord.[/dim]"
    )
    app_id = Prompt.ask("  ADZUNA_APP_ID").strip()
    app_key = Prompt.ask("  ADZUNA_APP_KEY").strip()
    if not app_id or not app_key:
        console.print("[yellow]Clés vides — Adzuna ignoré.[/yellow]")
        return False
    config.adzuna_app_id = app_id
    config.adzuna_app_key = app_key
    if Confirm.ask("  Sauvegarder dans .env pour les prochaines sessions ?", default=True):
        save_to_env("ADZUNA_APP_ID", app_id)
        save_to_env("ADZUNA_APP_KEY", app_key)
        console.print("[dim]Sauvegardé dans .env[/dim]")
    return True


_SOURCE_INFO: list[dict] = [
    {
        "key": "indeed",
        "label": "Indeed",
        "auth": False,
        "note": "Pas d'authentification requise",
    },
    {
        "key": "wttj",
        "label": "Welcome to the Jungle",
        "auth": False,
        "note": "Pas d'authentification requise",
    },
    {
        "key": "apec",
        "label": "Apec",
        "auth": False,
        "note": "Cadres en France — sans authentification",
    },
    {
        "key": "adzuna",
        "label": "Adzuna",
        "auth": True,
        "note": "API gratuite (1 000 appels/mois) — developer.adzuna.com",
        "configured": lambda: bool(config.adzuna_app_id and config.adzuna_app_key),
        "prompt": _prompt_adzuna_creds,
    },
    {
        "key": "ft",
        "label": "France Travail",
        "auth": True,
        "note": "Nécessite un compte partenaire (gratuit)",
        "configured": lambda: bool(config.france_travail_client_id and config.france_travail_client_secret),
        "prompt": _prompt_france_travail_creds,
    },
    {
        "key": "linkedin",
        "label": "LinkedIn",
        "auth": False,
        "note": "Mode invité sans compte (identifiants optionnels dans .env — CGU à vos risques)",
    },
]


def select_sources(preselected: str = "") -> list[str]:
    """Interactive source picker with on-the-fly credential prompting."""
    ok_mark = "[bold green]✓[/bold green]"
    lock_mark = "[bold yellow]⚠[/bold yellow]"

    # Si sources passées en argument CLI, on les prend telles quelles
    if preselected:
        keys = [s.strip() for s in preselected.split(",")]
        valid = {s["key"] for s in _SOURCE_INFO}
        unknown = [k for k in keys if k not in valid]
        if unknown:
            console.print(f"[yellow]Sources inconnues ignorées : {escape(', '.join(unknown))}[/yellow]")
        return [k for k in keys if k in valid]

    # Sinon, afficher le menu interactif
    grid = Table.grid(padding=(0, 2))
    grid.add_column(width=3, style="bold cyan")
    grid.add_column(width=5)
    grid.add_column(width=28)
    grid.add_column()

    for i, src in enumerate(_SOURCE_INFO, 1):
        if src["auth"]:
            configured = src["configured"]()
            status = ok_mark if configured else lock_mark
            note = "[green]configuré[/green]" if configured else f"[yellow]auth requise[/yellow] — {src['note']}"
        else:
            status = ok_mark
            note = f"[dim]{src['note']}[/dim]"
        grid.add_row(f"{i}.", status, src["label"], note)

    console.print(Panel(
        grid,
        title="[bold cyan]Choisir les sources de recherche[/bold cyan]",
        subtitle="[dim]Numéros séparés par virgule ou 'all' (défaut)[/dim]",
        border_style="cyan",
        padding=(1, 2),
    ))

    while True:
        choice = Prompt.ask("[bold cyan]Sources[/bold cyan]", default="all").strip().lower()
        if choice in ("", "all"):
            selected_info = _SOURCE_INFO
        elif choice == "q":
            sys.exit(0)
        else:
            try:
                indices = [int(x.strip()) - 1 for x in choice.split(",")]
                selected_info = [_SOURCE_INFO[i] for i in indices if 0 <= i < len(_SOURCE_INFO)]
                if not selected_info:
                    console.print("[red]Numéros hors plage, réessayez.[/red]")
                    continue
            except ValueError:
                console.print("[red]Format invalide. Exemple : 1,2  ou  all[/red]")
                continue

        # Pour chaque source avec auth non configurée, proposer de saisir les creds
        final_keys = []
        for src in selected_info:
            key = src["key"]
            if src["auth"] and not src["configured"]():
                console.print(f"\n[bold]{src['label']}[/bold] nécessite une authentification.")
                if Confirm.ask(f"  Configurer {src['label']} maintenant ?", default=True):
                    success = src["prompt"]()
                    if success:
                        final_keys.append(key)
                    else:
                        console.print(f"[dim]{src['label']} ignoré.[/dim]")
                else:
                    console.print(f"[dim]{src['label']} ignoré.[/dim]")
            else:
                final_keys.append(key)

        if not final_keys:
            console.print("[yellow]Aucune source valide. Au moins Indeed ou WTTJ recommandé.[/yellow]")
            continue

        labels = [s["label"] for s in _SOURCE_INFO if s["key"] in final_keys]
        console.print(f"[green]Sources retenues : {', '.join(labels)}[/green]")
        return final_keys


# ─── Scraping ─────────────────────────────────────────────────────────────────

def _run_one_scraper(source_key: str, query: str, location: str, max_per_source: int) -> tuple[str, list[JobOffer], str | None]:
    """Lance un scraper. Retourne (source_name, offers, error_message_or_None)."""
    source_name, scraper_cls = SOURCE_MAP[source_key]
    try:
        scraper = scraper_cls()
        offers = scraper.search(query, location, max_per_source)
        return source_name, offers, None
    except ValueError as e:
        return source_name, [], f"désactivé : {e}"
    except Exception as e:
        return source_name, [], f"erreur – {e}"


def scrape_all(sources: list[str], query: str, location: str, max_per_source: int) -> list[JobOffer]:
    """Scrape toutes les sources EN PARALLÈLE via un pool de threads."""
    valid_sources = [s for s in sources if s in SOURCE_MAP]
    for s in sources:
        if s not in SOURCE_MAP:
            console.print(f"[yellow]Source inconnue ignorée : {escape(s)}[/yellow]")

    if not valid_sources:
        return []

    if "linkedin" in valid_sources and config.linkedin_email and config.linkedin_password:
        console.print("[yellow]⚠  LinkedIn en mode connecté : contraire aux CGU, à vos risques (mode invité : retirez les identifiants du .env).[/yellow]")

    all_offers: list[JobOffer] = []
    seen_keys: set[str] = set()

    with Progress(SpinnerColumn(), TextColumn(f"[cyan]Scraping {len(valid_sources)} source(s) en parallèle..."), console=console) as progress:
        progress.add_task("", total=None)
        with ThreadPoolExecutor(max_workers=min(len(valid_sources), 5)) as executor:
            futures = {
                executor.submit(_run_one_scraper, key, query, location, max_per_source): key
                for key in valid_sources
            }
            for future in as_completed(futures):
                source_name, offers, error = future.result()
                if error:
                    color = "yellow" if "désactivé" in error else "red"
                    console.print(f"[{color}]⚠  {source_name} : {escape(error)}[/{color}]")
                    continue
                new_offers = [o for o in offers if o.unique_key() not in seen_keys]
                seen_keys.update(o.unique_key() for o in new_offers)
                all_offers.extend(new_offers)
                console.print(f"[green]✓ {source_name} : {len(new_offers)} offres[/green]")

    return all_offers


# ─── Affichage ────────────────────────────────────────────────────────────────

def _score_color(score: int) -> str:
    if score >= 8:
        return "green"
    if score >= 6:
        return "yellow"
    return "red"


def display_matches(offers: list[JobOffer], tracker: Tracker | None = None) -> None:
    table = Table(
        title=f"\n{len(offers)} offres correspondantes",
        box=box.ROUNDED,
        show_lines=True,
        header_style="bold cyan",
    )
    table.add_column("#", style="dim", width=4)
    table.add_column("", width=2)  # badge statut
    table.add_column("Score", width=7, justify="center")
    table.add_column("Poste", min_width=25)
    table.add_column("Entreprise", min_width=18)
    table.add_column("Lieu", min_width=12)
    table.add_column("Contrat", width=8)
    table.add_column("Salaire", width=14)
    table.add_column("Source", width=10)
    table.add_column("Correspondance", min_width=30)

    for i, offer in enumerate(offers, 1):
        score = offer.match_score or 0
        color = _score_color(score)
        badge = STATUS_BADGE.get(tracker.status_of(offer), "") if tracker else ""
        reasons = offer.match_reasons
        if isinstance(reasons, list):
            reasons = " · ".join(str(r) for r in reasons if r)
        reasons_str = str(reasons).strip() if reasons else "–"
        if offer.best_cv and offer.cv_scores:
            reasons_str = f"[CV : {offer.best_cv}] {reasons_str}"
        # escape() : le contenu vient du web ou du LLM — il ne doit jamais être
        # interprété comme du balisage Rich (spoofing de badges, liens cachés…)
        table.add_row(
            str(i),
            badge,
            f"[{color}]{score}/10[/{color}]",
            escape(offer.title),
            escape(offer.company),
            escape(offer.location or "–"),
            escape(offer.contract_type or "–"),
            escape(offer.salary or "–"),
            escape(offer.source),
            escape(reasons_str),
        )

    console.print(table)


def _parse_indices(raw: str, max_idx: int) -> list[int]:
    """Parse '1,3,5' ou '1-5' ou 'all' en liste d'index 0-based."""
    raw = raw.strip().lower()
    if raw == "all":
        return list(range(max_idx))
    indices: list[int] = []
    for part in raw.split(","):
        part = part.strip()
        if "-" in part:
            try:
                lo, hi = part.split("-", 1)
                indices.extend(range(int(lo) - 1, int(hi)))
            except ValueError:
                continue
        else:
            try:
                indices.append(int(part) - 1)
            except ValueError:
                continue
    return [i for i in indices if 0 <= i < max_idx]


def browse_offers(offers: list[JobOffer], tracker: Tracker | None = None,
                  letter_cb=None) -> None:
    """Navigation interactive après un scan. letter_cb(targets) : génération
    de lettres pour une sélection ('m N'), si un CV est disponible."""
    letter_hint = "[bold]m N[/bold] lettre · " if letter_cb else ""
    console.print(
        "\n[dim]Commandes : [bold]N[/bold] détail · [bold]o N[/bold] ouvrir · "
        "[bold]f N[/bold] favori · [bold]a N[/bold] postulé · [bold]r N[/bold] rejeter · "
        f"{letter_hint}[bold]l[/bold] relister · [bold]Entrée[/bold] quitter[/dim]"
    )
    console.print(
        "[dim]N peut être : [bold]3[/bold], [bold]1,3,5[/bold], [bold]1-5[/bold] ou [bold]all[/bold][/dim]"
    )

    while True:
        choice = Prompt.ask("[bold cyan]>[/bold cyan]", default="").strip().lower()
        if choice == "":
            break
        if choice == "l":
            display_matches(offers, tracker)
            continue

        # Commandes à 2 lettres : "o N", "f N", "a N", "r N", "m N"
        cmd, _, arg = choice.partition(" ")
        if cmd in ("o", "f", "a", "r", "m") and arg:
            indices = _parse_indices(arg, len(offers))
            if not indices:
                console.print(f"[red]Numéros invalides (1–{len(offers)}).[/red]")
                continue
            targets = [offers[i] for i in indices]
            if cmd == "o":
                for offer in targets:
                    if _safe_open_url(offer.url):
                        console.print(f"[dim]Ouverture : {escape(offer.url)}[/dim]")
            elif cmd == "m":
                if letter_cb is None:
                    console.print("[yellow]Lettres indisponibles ici (CV non chargé — relancez avec --cv).[/yellow]")
                else:
                    letter_cb(targets)
            elif tracker is not None and cmd == "f":
                tracker.mark_many(targets, "favorite")
                console.print(f"[yellow]★ {len(targets)} offre(s) marquée(s) comme favori.[/yellow]")
            elif tracker is not None and cmd == "a":
                tracker.mark_many(targets, "applied")
                console.print(f"[green]✓ {len(targets)} offre(s) marquée(s) comme postulée(s).[/green]")
            elif tracker is not None and cmd == "r":
                tracker.mark_many(targets, "rejected")
                console.print(f"[red]✗ {len(targets)} offre(s) rejetée(s) (ne réapparaîtront plus).[/red]")
            elif tracker is None:
                console.print("[yellow]Tracking désactivé.[/yellow]")
            continue

        # Numéro seul : afficher détail
        try:
            idx = int(choice) - 1
            if 0 <= idx < len(offers):
                _show_detail(offers[idx])
            else:
                console.print(f"[red]Numéro hors plage (1–{len(offers)}).[/red]")
        except ValueError:
            console.print("[red]Commande inconnue. Tapez un numéro, 'o/f/a/r/m N', 'l' ou Entrée.[/red]")


def _show_detail(offer: JobOffer) -> None:
    score = offer.match_score or 0
    color = _score_color(score)
    reasons = offer.match_reasons
    if isinstance(reasons, list):
        reasons = " · ".join(str(r) for r in reasons if r)
    reasons_str = str(reasons).strip() if reasons else ""

    # Lien cliquable seulement si l'URL est http(s) et ne peut pas casser le balisage
    if offer.url.startswith(("http://", "https://")) and "]" not in offer.url:
        url_line = f"[link={offer.url}]{escape(offer.url)}[/link]"
    else:
        url_line = escape(offer.url) or "–"

    meta_lines = [
        f"[bold]Entreprise :[/bold] {escape(offer.company)}",
        f"[bold]Lieu :[/bold]       {escape(offer.location or '–')}",
        f"[bold]Contrat :[/bold]    {escape(offer.contract_type or '–')}",
        f"[bold]Salaire :[/bold]    {escape(offer.salary or '–')}",
        f"[bold]Source :[/bold]     {escape(offer.source)}",
        f"[bold]Score :[/bold]      [{color}]{score}/10[/{color}]  {escape(reasons_str)}",
        f"[bold]URL :[/bold]        {url_line}",
    ]
    if offer.match_strengths:
        meta_lines.append(f"\n[bold green]Vos atouts :[/bold green]  {escape(offer.match_strengths)}")
    if offer.match_gaps:
        meta_lines.append(f"[bold yellow]À combler :[/bold yellow]   {escape(offer.match_gaps)}")
    if offer.cv_scores:
        meta_lines.append("\n[bold]Détail par CV :[/bold]")
        for label, r in sorted(offer.cv_scores.items(), key=lambda kv: -kv[1]["score"]):
            mark = " [cyan]◀ meilleur[/cyan]" if label == offer.best_cv else ""
            c = _score_color(r["score"])
            meta_lines.append(
                f"  [{c}]{r['score']}/10[/{c}]  {escape(label)}{mark}"
                + (f" — {escape(r['reasons'][:120])}" if r.get("reasons") else "")
            )
    meta = "\n".join(meta_lines)

    desc = escape((offer.description or "Pas de description disponible.").strip())
    if len(desc) > 1500:
        desc = desc[:1500] + "\n[dim]… (tronqué — ouvrez l'URL pour la suite)[/dim]"

    console.print(Panel(
        meta + "\n\n" + desc,
        title=f"[bold cyan]{escape(offer.title)}[/bold cyan]",
        border_style=color,
        padding=(1, 2),
    ))


# ─── Sélection et génération des lettres ──────────────────────────────────────

def select_offers(offers: list[JobOffer]) -> list[JobOffer]:
    console.print("\n[bold]Sélectionnez les offres pour lesquelles générer une lettre de motivation.[/bold]")
    console.print(
        "Numéros séparés par virgule, [cyan]'all'[/cyan] pour tout, "
        "[cyan]'o N'[/cyan] pour voir le détail, [cyan]'q'[/cyan] pour annuler."
    )

    while True:
        choice = Prompt.ask("[bold cyan]Sélection[/bold cyan]").strip().lower()
        if choice == "q":
            return []
        if choice == "all":
            return offers
        if choice.startswith("o "):
            try:
                idx = int(choice[2:].strip()) - 1
                if 0 <= idx < len(offers):
                    _show_detail(offers[idx])
                else:
                    console.print(f"[red]Numéro hors plage (1–{len(offers)}).[/red]")
            except ValueError:
                console.print("[red]Usage : o 3[/red]")
            continue
        try:
            indices = [int(x.strip()) - 1 for x in choice.split(",")]
            selected = [offers[i] for i in indices if 0 <= i < len(offers)]
            if selected:
                return selected
            console.print("[red]Sélection invalide, réessayez.[/red]")
        except (ValueError, IndexError):
            console.print("[red]Format invalide. Exemple : 1,3,5[/red]")


def _ask_tone() -> str:
    console.print("\n[bold]Ton des lettres :[/bold]")
    for key, desc in TONES.items():
        console.print(f"  [cyan]{key}[/cyan] — {desc}")
    return Prompt.ask(
        "[bold cyan]Ton[/bold cyan]",
        choices=list(TONES.keys()),
        default="standard",
    )


def generate_letters(offers: list[JobOffer], generator: CoverLetterGenerator,
                     tone: str = "standard", store: SessionStore | None = None) -> None:
    for offer in offers:
        label = escape(f"{offer.title} @ {offer.company}")
        with Progress(SpinnerColumn(), TextColumn(f"[cyan]Génération : {label}..."), console=console) as progress:
            progress.add_task("", total=None)
            try:
                result = generator.generate(offer, tone=tone)
                txt_path, pdf_path = generator.save(offer, result)
                if store is not None:
                    store.add_letter(
                        offer, tone, result.get("language", "fr"),
                        txt_path.name, pdf_path.name if pdf_path.exists() else "",
                    )

                # La lettre vient du LLM (lui-même exposé au texte de l'offre) :
                # on l'affiche comme du texte brut, jamais comme du balisage.
                body = ""
                if result.get("email_subject"):
                    body += f"[bold]Objet du mail :[/bold] {escape(result['email_subject'])}\n\n"
                body += escape(result["letter"])
                console.print(Panel(
                    body,
                    title=f"[bold green]{escape(offer.title)} – {escape(offer.company)}[/bold green]",
                    subtitle=f"[dim]{escape(str(txt_path))}[/dim]",
                    expand=False,
                ))

                if pdf_path.exists():
                    console.print(f"  [dim]PDF : {escape(str(pdf_path))}  (email d'accompagnement dans le .txt)[/dim]")

            except Exception as e:
                console.print(f"[red]Erreur génération pour {escape(offer.title)} : {escape(str(e))}[/red]")

        time.sleep(0.5)


# ─── Export ───────────────────────────────────────────────────────────────────

def _csv_safe(value) -> str:
    """Neutralise l'injection de formules : Excel/Sheets exécutent les cellules
    commençant par = + - @ — un titre d'offre hostile pourrait en profiter."""
    s = str(value) if value is not None else ""
    if s and s[0] in ("=", "+", "-", "@", "\t", "\r"):
        return "'" + s
    return s


def _ascii_slug(text: str, limit: int = 30) -> str:
    """Nom de fichier sûr ET téléchargeable : accents translittérés (é → e),
    tout caractère hors [a-zA-Z0-9_-] remplacé. Les accents conservés
    cassaient le téléchargement web (« développeur » → « Fichier non autorisé »)."""
    import unicodedata
    folded = unicodedata.normalize("NFKD", text).encode("ascii", "ignore").decode("ascii")
    return ("".join(c if c.isalnum() else "_" for c in folded)[:limit].strip("_")
            or "recherche")


def save_results(offers: list[JobOffer], query: str) -> tuple[Path, Path]:
    from output_paths import offers_scored_dir
    out = offers_scored_dir()
    safe_query = _ascii_slug(query)

    json_path = out / f"resultats_{safe_query}.json"
    csv_path = out / f"resultats_{safe_query}.csv"

    rows = [
        {
            "titre": o.title,
            "entreprise": o.company,
            "lieu": o.location or "",
            "contrat": o.contract_type or "",
            "salaire": o.salary or "",
            "source": o.source,
            "score": o.match_score,
            "correspondance": o.match_reasons or "",
            "url": o.url,
        }
        for o in offers
    ]

    json_path.write_text(json.dumps(rows, ensure_ascii=False, indent=2), encoding="utf-8")

    with csv_path.open("w", newline="", encoding="utf-8-sig") as f:
        writer = csv.DictWriter(f, fieldnames=rows[0].keys())
        writer.writeheader()
        writer.writerows([{k: _csv_safe(v) for k, v in row.items()} for row in rows])

    console.print(f"\n[dim]JSON : {json_path}[/dim]")
    console.print(f"[dim]CSV  : {csv_path}  (Excel / Google Sheets)[/dim]")
    return json_path, csv_path


def save_raw_offers(offers: list[JobOffer], query: str) -> Path:
    """Offres brutes (avant analyse IA) → output/offres/brutes/ — sert au mode
    test scraper (sans IA) pour prévisualiser et ajuster les filtres."""
    from output_paths import offers_raw_dir
    path = offers_raw_dir() / f"brutes_{_ascii_slug(query)}.json"
    rows = [
        {
            "titre": o.title, "entreprise": o.company, "lieu": o.location or "",
            "contrat": o.contract_type or "", "salaire": o.salary or "",
            "source": o.source, "url": o.url,
            "description": (o.description or "")[:4000],
        }
        for o in offers
    ]
    path.write_text(json.dumps(rows, ensure_ascii=False, indent=2), encoding="utf-8")
    return path


def save_dropped_offers(offers: list[JobOffer], query: str, reason: str) -> Path | None:
    """Offres collectées mais non retenues → output/offres/ecartees/ —
    traçabilité de ce que le pipeline a éliminé (déjà vues, score insuffisant…)."""
    if not offers:
        return None
    from output_paths import offers_dropped_dir
    path = offers_dropped_dir() / f"ecartees_{_ascii_slug(query)}.json"
    rows = [
        {
            "titre": o.title, "entreprise": o.company, "lieu": o.location or "",
            "source": o.source, "url": o.url, "score": o.match_score,
            "raison": reason,
        }
        for o in offers
    ]
    path.write_text(json.dumps(rows, ensure_ascii=False, indent=2), encoding="utf-8")
    return path


# ─── Historique des sessions ──────────────────────────────────────────────────

def _criteria_summary(criteria: dict) -> str:
    parts = []
    if criteria.get("location"):
        parts.append(criteria["location"])
    if criteria.get("country") and criteria.get("country") != "fr":
        parts.append(COUNTRY_NAMES.get(criteria["country"], criteria["country"]))
    if criteria.get("experience"):
        parts.append(criteria["experience"])
    if criteria.get("sectors"):
        parts.append(f"{len(criteria['sectors'])} secteur(s)")
    return " · ".join(parts) or "–"


def _session_cv_display(cv_store: CVStore, criteria_cv: str) -> str:
    """Libellé(s) du/des CV d'une session : « CV supprimé : x » si le CV
    n'existe plus — l'historique reste cohérent après une suppression."""
    names = [n.strip() for n in str(criteria_cv or "").split(",") if n.strip()]
    labels = []
    for name in names:
        name = Path(name).name
        exists = (_PROJECT_DIR / name).is_file() or Path(name).is_file()
        labels.append(cv_store.history_label(name, exists))
    return " + ".join(lab for lab in labels if lab)


def show_sessions() -> None:
    """Liste les sessions de recherche passées (--sessions)."""
    store = _get_store()
    sessions = store.list_sessions()
    if not sessions:
        console.print(Panel(
            "[dim]Aucune session enregistrée. Lancez un scan pour commencer ![/dim]",
            title="[bold cyan]Historique des sessions[/bold cyan]", border_style="cyan",
        ))
        return

    cv_store = _get_cv_store()
    table = Table(title="Historique des sessions", box=box.ROUNDED, header_style="bold cyan")
    table.add_column("#", style="dim", width=4)
    table.add_column("Date", width=17)
    table.add_column("Type", width=8)
    table.add_column("Recherche", min_width=18)
    table.add_column("CV", min_width=12)
    table.add_column("Critères", min_width=16)
    table.add_column("Offres", width=12, justify="center")
    table.add_column("ID", style="dim")
    for i, s in enumerate(sessions, 1):
        c = s["criteria"]
        table.add_row(
            str(i),
            escape(s["date"].replace("T", " ")[:16]),
            escape(s["kind"]),
            escape(c.get("query") or "–"),
            escape(_session_cv_display(cv_store, c.get("cv", "")) or "–"),
            escape(_criteria_summary(c)),
            f"{s['kept']}/{s['found']}",
            escape(s["id"]),
        )
    console.print(table)

    letters = store.list_letters()
    if letters:
        console.print(f"[dim]{len(letters)} lettre(s) générée(s) au total — fichiers dans {config.output_dir}/[/dim]")
    console.print(
        "\n[dim]Revoir une session : [bold]python main.py --session N[/bold] · "
        "Relancer avec les mêmes critères : [bold]python main.py --rerun N --cv cv.pdf[/bold][/dim]"
    )


# ─── Gestion des CV (registre) ───────────────────────────────────────────────

def show_cvs() -> None:
    """Liste les CV connus du registre (--list-cvs)."""
    store = _get_cv_store()
    store.sync(list_cv_files(_PROJECT_DIR))
    entries = store.list_cvs(include_deleted=True)
    if not entries:
        console.print(Panel(
            "[dim]Aucun CV connu. Déposez un PDF/DOCX/TXT dans le dossier du "
            "projet ou lancez un scan avec --cv.[/dim]",
            title="[bold cyan]Mes CV[/bold cyan]", border_style="cyan",
        ))
        return

    table = Table(title="CV connus", box=box.ROUNDED, header_style="bold cyan")
    table.add_column("ID", style="dim", width=10)
    table.add_column("Label", min_width=16)
    table.add_column("Fichier", min_width=16)
    table.add_column("Ajouté", width=12)
    table.add_column("Profil IA", width=12)
    table.add_column("Statut", width=22)
    for e in entries:
        exists = (_PROJECT_DIR / e.get("filename", "")).is_file()
        if e.get("deleted"):
            status = f"[red]supprimé le {e.get('deleted_date', '')[:10]}[/red]"
        elif not exists:
            status = "[yellow]fichier introuvable[/yellow]"
        else:
            status = "[green]actif[/green]"
        analyzed = e.get("analyzed", "")
        overrides = "✎ " if e.get("overrides") else ""
        table.add_row(
            escape(e.get("id", "")),
            escape(e.get("label", "")),
            escape(e.get("filename", "")),
            escape(e.get("added", "")[:10]),
            f"{overrides}{escape(analyzed[:10])}" if analyzed else "[dim]non analysé[/dim]",
            status,
        )
    console.print(table)
    console.print(
        "[dim]Profil détaillé + édition : interface web (python web.py → Mes CV) · "
        "Suppression : python main.py --delete-cv ID_OU_NOM[/dim]"
    )


def delete_cv(ref: str) -> None:
    """Supprime un CV (--delete-cv) : fichier + cache effacés, tombstone dans
    le registre — l'historique des sessions garde « CV supprimé : x »."""
    store = _get_cv_store()
    store.sync(list_cv_files(_PROJECT_DIR))
    entry = store.get(ref)
    if entry is None:
        console.print(f"[red]CV introuvable : {escape(ref)}[/red]")
        console.print("[dim]Listez les CV connus avec : python main.py --list-cvs[/dim]")
        sys.exit(1)

    filename = entry.get("filename", "")
    label = entry.get("label", filename)
    console.print(
        f"[bold]CV à supprimer :[/bold] {escape(label)} [dim]({escape(filename)})[/dim]\n"
        "[yellow]Action irréversible : le fichier et son cache seront effacés. "
        "Les sessions et lettres déjà générées restent dans l'historique, où ce "
        f"CV apparaîtra comme « CV supprimé : {escape(label)} ».[/yellow]"
    )
    if not Confirm.ask("[bold red]Confirmer la suppression ?[/bold red]", default=False):
        console.print("[dim]Suppression annulée.[/dim]")
        return

    # Fichier effacé AVANT le tombstone : si l'effacement échouait après coup,
    # le prochain sync ré-enregistrerait le fichier restant comme un CV actif
    # neuf et la suppression serait silencieusement annulée.
    # (Jamais en dehors du projet : nom nu, résolution vérifiée.)
    target = (_PROJECT_DIR / Path(filename).name).resolve()
    if target.parent == _PROJECT_DIR and target.is_file():
        try:
            target.unlink()
            console.print(f"[dim]Fichier effacé : {escape(target.name)}[/dim]")
        except OSError as e:
            console.print(f"[red]Impossible d'effacer le fichier ({escape(str(e))}) — suppression annulée.[/red]")
            sys.exit(1)
        # Cache de parsing associé (output/.cv_<stem>_<hash>.txt)
        from cv_parser import _cache_path
        cache = _cache_path(target)
        if cache.is_file():
            try:
                cache.unlink()
            except OSError:
                pass
    store.mark_deleted(entry["id"])
    console.print(f"[green]✓ CV supprimé : {escape(label)}[/green]")


def _resolve_session(ref: str) -> dict | None:
    """Accepte l'ID complet ou le numéro affiché par --sessions (1 = plus récente)."""
    store = _get_store()
    session = store.get_session(ref.strip())
    if session is not None:
        return session
    try:
        index = int(ref) - 1
    except ValueError:
        return None
    summaries = store.list_sessions()
    if 0 <= index < len(summaries):
        return store.get_session(summaries[index]["id"])
    return None


def browse_session(ref: str, cv_paths: list[str] | None = None) -> None:
    """Affiche les offres d'une session passée avec leurs scores de l'époque
    (--session N). Avec --cv, la génération de lettres ('m N') est disponible."""
    session = _resolve_session(ref)
    if session is None:
        console.print(f"[red]Session introuvable : {escape(ref)}[/red]")
        console.print("[dim]Listez les sessions avec : python main.py --sessions[/dim]")
        sys.exit(1)

    store = _get_store()
    offers = store.session_offers(session)
    c = session.get("criteria", {})
    cv_display = _session_cv_display(_get_cv_store(), c.get("cv", ""))
    console.print(Panel.fit(
        f"[bold cyan]Session {escape(session['id'])}[/bold cyan]\n"
        f"Date : {escape(session.get('date', '').replace('T', ' ')[:16])} · "
        f"Type : {escape(session.get('kind', ''))}"
        + (f" · CV : {escape(cv_display)}" if cv_display else "") + "\n"
        f"Recherche : « {escape(c.get('query') or '–')} » · {escape(_criteria_summary(c))}\n"
        f"Offres : {len(offers)} retenue(s) sur {session.get('found', 0)} collectée(s)",
        border_style="cyan",
    ))
    if not offers:
        return

    tracker = Tracker(Path(config.output_dir) / ".tracker.json")
    display_matches(offers, tracker)

    letter_cb = None
    if cv_paths:
        try:
            cv_texts = _load_cv_texts(cv_paths)
            letter_cb = _make_letter_cb(cv_texts, tracker)
        except (FileNotFoundError, ValueError) as e:
            console.print(f"[yellow]CV illisible ({escape(str(e))}) — lettres indisponibles.[/yellow]")
    else:
        console.print("[dim]Ajoutez --cv votre_cv.pdf pour générer des lettres depuis cette session.[/dim]")
    browse_offers(offers, tracker, letter_cb=letter_cb)


def _make_letter_cb(cv_texts: dict[str, str], tracker: Tracker):
    """Callback 'm N' du mode navigation : génère les lettres des offres
    ciblées. Plusieurs CV → fusion avec provenance dans le prompt."""
    state: dict = {"generator": None}

    def callback(targets: list[JobOffer]) -> None:
        tone = _ask_tone()
        if state["generator"] is None:
            applied_titles = [
                str(e.get("title", "")) for e in tracker.list_by_status("applied") if e.get("title")
            ]
            state["generator"] = CoverLetterGenerator(
                merge_cv_texts(cv_texts),
                applied_history=applied_titles,
                style_examples=_style_examples(),
            )
        generate_letters(targets, state["generator"], tone=tone, store=_get_store())
        tracker.mark_many(targets, "applied")
        console.print(f"[dim]→ {len(targets)} offre(s) marquée(s) comme postulée(s).[/dim]")

    return callback


# ─── Détection des LLM locaux ─────────────────────────────────────────────────

def show_local_models() -> None:
    """`--scan-models` : serveurs LLM locaux actifs, matériel, suggestions."""
    from integrations import scan_local_models
    console.print("[dim]Détection des serveurs LLM locaux (Ollama, LM Studio, llama.cpp)…[/dim]")
    report = scan_local_models()

    ram, vram = report["ram_gb"], report["vram_gb"]
    hw = f"RAM : {ram} Go" if ram else "RAM : inconnue"
    hw += f" · VRAM GPU : {vram} Go" if vram else " · pas de GPU NVIDIA détecté"
    console.print(f"[bold]Matériel[/bold] — {hw}")

    if not report["servers"]:
        console.print(
            "[yellow]Aucun serveur LLM local détecté.[/yellow] "
            "[dim]Ollama : https://ollama.com · LM Studio : https://lmstudio.ai[/dim]"
        )
    for server in report["servers"]:
        table = Table(title=f"{server['server']} — {server['url']}", box=box.SIMPLE)
        table.add_column("Modèle")
        table.add_column("Taille", justify="right")
        for m in server["models"] or [{"name": "(aucun modèle installé)", "size_gb": None}]:
            table.add_row(escape(m["name"]), f"{m['size_gb']} Go" if m["size_gb"] else "–")
        console.print(table)

    if report["suggestions"]:
        console.print("[bold]Modèles conseillés pour cette machine :[/bold]")
        for s in report["suggestions"]:
            console.print(f"  • [cyan]{escape(s['model'])}[/cyan] — {escape(s['reason'])}")
        console.print("[dim]Installation : ollama pull <modèle> · puis OLLAMA_MODEL=<modèle> dans .env[/dim]")


# ─── Statistiques tracking ────────────────────────────────────────────────────

def show_stats() -> None:
    """Affiche un récap des offres trackées sur toutes les sessions."""
    tracker = Tracker(Path(config.output_dir) / ".tracker.json")
    counts = tracker.stats()

    if counts["total"] == 0:
        console.print(Panel(
            "[dim]Aucune offre encore trackée. Lancez un scan pour commencer ![/dim]",
            title="[bold cyan]Historique de candidature[/bold cyan]",
            border_style="cyan",
        ))
        return

    summary = "\n".join([
        f"  [bold]{counts['total']}[/bold] offres connues au total",
        "",
        f"  [yellow]★ Favoris   :[/yellow]  {counts['favorite']}",
        f"  [green]✓ Postulées :[/green]  {counts['applied']}",
        f"  [red]✗ Rejetées  :[/red]  {counts['rejected']}",
        f"  [dim]· Vues       :  {counts['seen']}[/dim]",
    ])
    console.print(Panel(
        summary,
        title="[bold cyan]Historique de candidature[/bold cyan]",
        border_style="cyan",
        padding=(1, 3),
    ))

    # Relances : candidatures sans suite depuis plus de 14 jours
    followups = tracker.needing_followup(days=14)
    if followups:
        table = Table(
            title="\n⏰ À relancer (postulées il y a plus de 14 jours)",
            box=box.ROUNDED, header_style="bold magenta",
        )
        table.add_column("Postulée le", style="dim", width=12)
        table.add_column("Poste", min_width=25)
        table.add_column("Entreprise", min_width=18)
        table.add_column("URL", overflow="fold")
        for entry in followups[:15]:
            table.add_row(
                escape(entry.get("updated", "")[:10]),
                escape(str(entry.get("title", "–"))),
                escape(str(entry.get("company", "–"))),
                escape(str(entry.get("url", "–"))),
            )
        console.print(table)
        console.print("[dim]Conseil : une relance courte 2-3 semaines après l'envoi double les taux de réponse.[/dim]")

    # Détail des candidatures envoyées (toujours intéressant à voir)
    applied = tracker.list_by_status("applied")
    if applied:
        table = Table(title="\nCandidatures envoyées", box=box.ROUNDED, header_style="bold green")
        table.add_column("Date", style="dim", width=11)
        table.add_column("Poste", min_width=25)
        table.add_column("Entreprise", min_width=18)
        table.add_column("Source", width=10)
        for entry in sorted(applied, key=lambda x: x.get("updated", ""), reverse=True)[:20]:
            date = entry.get("updated", "")[:10]
            table.add_row(
                escape(date),
                escape(str(entry.get("title", "–"))),
                escape(str(entry.get("company", "–"))),
                escape(str(entry.get("source", "–"))),
            )
        console.print(table)

    favs = tracker.list_by_status("favorite")
    if favs:
        table = Table(title="\nFavoris", box=box.ROUNDED, header_style="bold yellow")
        table.add_column("Poste", min_width=25)
        table.add_column("Entreprise", min_width=18)
        table.add_column("Source", width=10)
        table.add_column("URL", overflow="fold")
        for entry in favs[:20]:
            table.add_row(
                escape(str(entry.get("title", "–"))),
                escape(str(entry.get("company", "–"))),
                escape(str(entry.get("source", "–"))),
                escape(str(entry.get("url", "–"))),
            )
        console.print(table)


# ─── Re-scoring sans nouvelle recherche ───────────────────────────────────────

def rescore_known_offers(args, cv_texts: dict[str, str]) -> None:
    """Re-score le(s) CV contre toutes les offres déjà connues (toutes
    sessions confondues), sans relancer les scrapers. Pré-filtre code pur
    (top {RESCORE_TOP_K} par similarité mots-clés) puis pré-scoring IA rapide
    avant l'analyse détaillée."""
    store = _get_store()
    offers = store.all_offers()
    if not offers:
        console.print(
            "[yellow]Aucune offre connue pour l'instant.[/yellow] "
            "[dim]Lancez d'abord un scan : python main.py --cv cv.pdf --scan[/dim]"
        )
        return

    console.print(f"\n[bold]Re-scoring :[/bold] {len(offers)} offre(s) connue(s) dans l'historique")

    tracker = Tracker(Path(config.output_dir) / ".tracker.json")
    if not args.include_seen:
        before = len(offers)
        offers = tracker.filter_visible(offers)
        hidden = before - len(offers)
        if hidden:
            console.print(f"[dim]{hidden} offre(s) déjà traitée(s) filtrée(s) (--include-seen pour les inclure).[/dim]")
    if not offers:
        console.print("[yellow]Toutes les offres connues sont déjà traitées.[/yellow]")
        return

    sectors = select_sectors(args.sectors) if args.sectors else []
    exclude = parse_exclude_keywords(config.exclude_keywords) + parse_exclude_keywords(args.exclude)
    rejections = tracker.recent_rejections()

    with Progress(SpinnerColumn(), TextColumn("[cyan]Re-scoring en cours..."), console=console) as progress:
        progress.add_task("", total=None)
        matched = score_offers_multi(
            cv_texts,
            offers,
            min_score=args.min_score,
            sectors=sectors,
            exclude=exclude,
            experience_level=args.experience,
            rejected_examples=rejections,
            top_k=RESCORE_TOP_K,
            two_stage=True,
        )

    if not matched:
        console.print(f"[yellow]Aucune offre connue avec un score ≥ {args.min_score}/10 pour ce CV.[/yellow]")
        return

    display_matches(matched, tracker)
    save_results(matched, "rescore")
    tracker.mark_many(matched, "seen")
    store.add_session(
        kind="rescore",
        criteria={
            "query": "(re-scoring de la base)",
            "cv": ",".join(Path(p).name for p in args.cv),
            "country": config.country,
            "location": "",
            "sectors": _sector_keys(sectors),
            "experience": args.experience,
            "sources": [],
            "min_score": args.min_score,
            "exclude": exclude,
        },
        offers=matched,
        found=len(offers),
    )
    browse_offers(matched, tracker, letter_cb=_make_letter_cb(cv_texts, tracker))


# ─── Critères par défaut (persistés entre les sessions) ───────────────────────

def _persist_defaults(sources: list[str], sector_labels: list[str],
                      location: str, experience: str) -> None:
    """Mémorise les derniers critères choisis interactivement — reproposés au
    prochain lancement et utilisés comme défauts par l'interface web."""
    try:
        save_to_env("DEFAULT_SOURCES", ",".join(sources))
        save_to_env("DEFAULT_SECTORS", ",".join(_sector_keys(sector_labels)))
        save_to_env("DEFAULT_LOCATION", location)
        save_to_env("DEFAULT_COUNTRY", config.country)
        save_to_env("DEFAULT_EXPERIENCE", experience)
    except (ValueError, OSError):
        pass  # défauts non persistés : sans gravité


def _describe_defaults() -> str:
    parts = []
    if config.default_sectors:
        parts.append(f"secteurs : {config.default_sectors}")
    loc = config.default_location or "sans filtre"
    country = COUNTRY_NAMES.get(config.default_country, "France")
    parts.append(f"lieu : {loc} ({country})")
    if config.default_experience:
        parts.append(f"niveau : {config.default_experience}")
    if config.default_sources:
        parts.append(f"sources : {config.default_sources}")
    return " · ".join(parts)


# ─── Mode veille ──────────────────────────────────────────────────────────────

def watch_loop(args, sources, sectors, cv_texts, tracker, exclude, location="", experience="") -> None:
    """Relance la recherche à intervalle régulier et ne signale que les
    offres jamais vues. Notification desktop quand il y a du nouveau."""
    interval_min = max(15, min(1440, args.watch))
    query = args.query.strip()
    rejections = tracker.recent_rejections()
    console.print(Panel.fit(
        f"[bold cyan]Mode veille[/bold cyan] — « {escape(query)} » toutes les {interval_min} min\n"
        "[dim]Seules les offres jamais vues sont signalées. Ctrl+C pour arrêter.[/dim]",
        border_style="cyan",
    ))
    cycle = 0
    while True:
        cycle += 1
        console.print(f"\n[bold]── Cycle {cycle} — {time.strftime('%H:%M')} ──[/bold]")
        try:
            all_offers = scrape_all(sources, query, location, args.max)
            new_offers = tracker.filter_unseen(all_offers)
            if not new_offers:
                console.print("[dim]Aucune nouvelle offre depuis le dernier cycle.[/dim]")
            else:
                matched = score_offers_multi(
                    cv_texts, new_offers, min_score=args.min_score, sectors=sectors,
                    exclude=exclude, experience_level=experience,
                    rejected_examples=rejections,
                )
                # Tout ce qui a été analysé est marqué vu : pas de re-scoring au prochain cycle
                tracker.mark_many(new_offers, "seen")
                if matched:
                    display_matches(matched, tracker)
                    save_results(matched, query)
                    _get_store().add_session(
                        kind="watch",
                        criteria={
                            "query": query,
                            "cv": ",".join(Path(p).name for p in args.cv),
                            "country": config.country, "location": location,
                            "sectors": _sector_keys(sectors), "experience": experience,
                            "sources": sources, "min_score": args.min_score,
                            "exclude": exclude,
                        },
                        offers=matched,
                        found=len(new_offers),
                    )
                    if args.notion and notion_configured():
                        export_to_notion(matched)
                    best = matched[0]
                    desktop_notify(
                        f"{len(matched)} nouvelle(s) offre(s) d'emploi",
                        f"Meilleure : {best.title} @ {best.company} ({best.match_score}/10)",
                    )
                else:
                    console.print(f"[dim]{len(new_offers)} nouvelle(s) offre(s), aucune ≥ {args.min_score}/10.[/dim]")
        except KeyboardInterrupt:
            console.print("\n[dim]Mode veille arrêté.[/dim]")
            return
        except Exception as e:
            console.print(f"[red]Erreur du cycle : {escape(str(e))}[/red]")

        next_at = time.strftime("%H:%M", time.localtime(time.time() + interval_min * 60))
        console.print(f"[dim]Prochain scan à {next_at}. Ctrl+C pour arrêter.[/dim]")
        try:
            time.sleep(interval_min * 60)
        except KeyboardInterrupt:
            console.print("\n[dim]Mode veille arrêté.[/dim]")
            return


# ─── Point d'entrée ───────────────────────────────────────────────────────────

def parse_args():
    parser = argparse.ArgumentParser(
        description="Recherche et postule automatiquement aux offres d'emploi.",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog=(
            "Exemples :\n"
            "  python main.py --check                           # Diagnostic\n"
            "  python main.py --stats                           # Historique candidatures\n"
            "  python main.py --cv cv.pdf --scan                # Scan sans postuler\n"
            "  python main.py --cv cv.pdf --query \"dev Python\" --location \"Paris\" --sectors tech\n"
            "  python main.py --sessions                        # Sessions de recherche passées\n"
            "  python main.py --session 1 --cv cv.pdf           # Revoir une session (lettres : m N)\n"
            "  python main.py --rerun 1 --cv cv.pdf             # Relancer avec les mêmes critères\n"
            "  python main.py --rescore --cv cv.pdf             # Re-scorer la base sans scraper\n"
            "  python main.py --cv a.pdf --cv b.pdf --scan      # Matching multi-CV (meilleur score par offre)\n"
            "  python main.py --list-cvs                        # CV connus du registre\n"
            "  python main.py --delete-cv mon_cv.pdf            # Supprimer un CV (l'historique garde son nom)\n"
        ),
    )
    parser.add_argument("--check", action="store_true", help="Vérifier l'environnement et quitter")
    parser.add_argument("--stats", action="store_true", help="Afficher l'historique des candidatures et favoris")
    parser.add_argument("--sessions", action="store_true", help="Lister les sessions de recherche passées")
    parser.add_argument("--session", default="", metavar="ID",
                        help="Revoir les offres d'une session passée (numéro ou ID de --sessions)")
    parser.add_argument("--rerun", default="", metavar="ID",
                        help="Relancer une recherche avec les critères d'une session passée")
    parser.add_argument("--rescore", action="store_true",
                        help="Re-scorer le CV contre toutes les offres déjà connues, sans scraper")
    parser.add_argument("--list-cvs", action="store_true",
                        help="Lister les CV connus du registre (labels, profils, statut)")
    parser.add_argument("--delete-cv", default="", metavar="ID|NOM",
                        help="Supprimer un CV par identifiant, nom de fichier ou label (irréversible ; l'historique garde son nom)")
    parser.add_argument("--cv", action="append",
                        help="Chemin vers votre CV (PDF, DOCX ou TXT) — répétable pour un matching multi-CV : --cv a.pdf --cv b.pdf")
    parser.add_argument("--query", default="", help='Recherche ex: "développeur Python senior" (optionnel : demandé interactivement si absent)')
    parser.add_argument(
        "--global-search", action="store_true", dest="global_search",
        help="Recherche globale : les intitulés de poste sont générés par l'IA depuis vos CV (aucune --query à fournir)",
    )
    parser.add_argument("--location", default="", help='Localisation ex: "Paris" (sinon sélecteur interactif pays/région/ville)')
    parser.add_argument(
        "--country", default="fr", choices=[c for c, _ in COUNTRIES],
        help="Pays de recherche (défaut: fr) — utilisé avec --location ou --watch",
    )
    parser.add_argument(
        "--sources", default="apec,adzuna,indeed,wttj",
        help="Sources : ft,indeed,wttj,apec,adzuna,linkedin (défaut: apec,adzuna,indeed,wttj)",
    )
    parser.add_argument(
        "--max", type=int, default=config.max_jobs_per_source,
        help="Max offres par source — 0 = sans plafond (les sources gardent leurs limites internes), recommandé surtout avec un LLM local",
    )
    parser.add_argument("--min-score", type=int, default=config.min_match_score, help="Score minimum /10 (défaut: 6)")
    parser.add_argument(
        "--sectors", default="",
        help="Secteurs cibles : " + ", ".join(k for k, _ in SECTORS),
    )
    parser.add_argument("--scan", action="store_true", help="Scan uniquement : affiche et exporte sans générer de lettres")
    parser.add_argument(
        "--no-ai", action="store_true", dest="no_ai",
        help="Mode test scraper : collecte et affiche les offres brutes SANS aucun appel IA "
             "(export dans output/offres/brutes/) — pour ajuster requête et filtres sans consommer de tokens",
    )
    parser.add_argument("--no-letters", action="store_true", help="Analyse complète mais sans étape de génération de lettres")
    parser.add_argument(
        "--scan-models", action="store_true", dest="scan_models",
        help="Détecter les serveurs LLM locaux (Ollama, LM Studio, llama.cpp), la RAM/VRAM et suggérer des modèles",
    )
    parser.add_argument(
        "--include-seen", action="store_true",
        help="Inclure les offres déjà postulées ou rejetées dans les résultats",
    )
    parser.add_argument(
        "--exclude", default="",
        help='Mots-clés éliminatoires, séparés par virgule (ex: "senior,anglais courant") — s\'ajoutent à EXCLUDE_KEYWORDS du .env',
    )
    parser.add_argument(
        "--tone", default="", choices=["", *TONES.keys()],
        help="Ton des lettres : standard, formelle ou directe (sinon demandé interactivement)",
    )
    parser.add_argument(
        "--notion", action="store_true",
        help="Exporter les offres retenues vers Notion (NOTION_TOKEN + NOTION_DATABASE_ID requis)",
    )
    parser.add_argument(
        "--experience", default="",
        choices=["", *[k for k, _ in EXPERIENCE_LEVELS]],
        metavar="{" + ",".join(k for k, _ in EXPERIENCE_LEVELS) + "}",
        help="Niveau d'expérience : stage, junior, confirme, senior, expert (sinon demandé interactivement)",
    )
    parser.add_argument(
        "--watch", type=int, default=0, metavar="MINUTES",
        help="Mode veille : relance la recherche toutes les N minutes (15-1440) et notifie les nouvelles offres. Requiert --query.",
    )
    return parser.parse_args()


def main():
    args = parse_args()

    # Bornes de sécurité sur les arguments numériques
    # --max 0 = sans plafond : sentinelle au-delà des limites de pagination
    # internes des scrapers, qui bornent le volume réel
    args.max = 10_000 if args.max <= 0 else min(args.max, 10_000)
    args.min_score = max(0, min(10, args.min_score))

    # Mode vérification
    if args.check:
        check_setup()
        return

    # Mode stats
    if args.stats:
        show_stats()
        return

    # Détection des LLM locaux
    if args.scan_models:
        show_local_models()
        return

    # Gestion des CV (registre)
    if args.list_cvs:
        show_cvs()
        return
    if args.delete_cv:
        delete_cv(args.delete_cv)
        return

    # Historique des sessions
    if args.sessions:
        show_sessions()
        return
    if args.session:
        browse_session(args.session, args.cv or [])
        return

    # Relance d'une session passée : reprendre ses critères
    if args.rerun:
        past = _resolve_session(args.rerun)
        if past is None:
            console.print(f"[red]Session introuvable : {escape(args.rerun)}[/red]")
            console.print("[dim]Listez les sessions avec : python main.py --sessions[/dim]")
            sys.exit(1)
        c = past.get("criteria", {})
        args.query = c.get("query", "") if not c.get("query", "").startswith("(") else ""
        args.location = c.get("location", "")
        args.country = c.get("country", "fr")
        if c.get("sources"):
            args.sources = ",".join(c["sources"])
        args.sectors = ",".join(c.get("sectors") or [])
        args.experience = c.get("experience", "")
        args.min_score = max(0, min(10, int(c.get("min_score", args.min_score))))
        if c.get("exclude"):
            args.exclude = ",".join(c["exclude"])
        if not args.cv and c.get("cv"):
            # Le critère CV peut référencer plusieurs fichiers ("a.pdf,b.pdf")
            candidates = [n.strip() for n in c["cv"].split(",") if n.strip()]
            found = [n for n in candidates
                     if Path(n).is_file() or (_PROJECT_DIR / Path(n).name).is_file()]
            args.cv = [n if Path(n).is_file() else str(_PROJECT_DIR / Path(n).name)
                       for n in found] or None
        console.print(f"[dim]Critères repris de la session {escape(past['id'])} : "
                      f"« {escape(args.query or '–')} » · {escape(_criteria_summary(c))}[/dim]")

    console.print(Panel.fit(
        "[bold cyan]Auto Job Application[/bold cyan]\n"
        + ("[bold yellow]MODE SCAN — aucune candidature ne sera envoyée[/bold yellow]" if args.scan
           else "Recherche · Matching IA · Lettres de motivation"),
        border_style="cyan",
    ))

    # 1. CV (obligatoire sauf --check et --no-ai) — répétable pour le matching multi-CV
    if not args.cv and not args.no_ai:
        console.print("[red]--cv est requis. Exemple : python main.py --cv mon_cv.pdf --scan[/red]")
        console.print("[dim]Conseil : lancez d'abord  python main.py --check  pour vérifier votre configuration.[/dim]")
        console.print("[dim]Sans CV ni IA : python main.py --no-ai --query \"...\" (test scraper).[/dim]")
        sys.exit(1)

    cv_texts: dict[str, str] = {}
    if args.cv:
        args.cv = args.cv[:5]  # garde-fou : 5 CV max par session
        plural = "x" if len(args.cv) > 1 else ""
        console.print(f"\n[bold]1. Lecture du{plural} CV :[/bold] {', '.join(args.cv)}")
        try:
            cv_texts = _load_cv_texts(args.cv)
            total = sum(len(t) for t in cv_texts.values())
            console.print(f"[green]✓ {len(cv_texts)} CV parsé(s) ({total} caractères)[/green]")
        except (FileNotFoundError, ValueError) as e:
            console.print(f"[red]Erreur CV : {escape(str(e))}[/red]")
            sys.exit(1)
    else:
        args.cv = []
        console.print("\n[bold yellow]Mode test scraper (--no-ai) : aucun CV ni appel IA.[/bold yellow]")

    # 2. Vérification provider IA (inutile en mode test scraper)
    if args.no_ai:
        pass
    elif config.provider == "ollama":
        ollama_ok, _ = _check_ollama()
        if not ollama_ok:
            console.print(f"[red]Ollama n'est pas démarré sur {config.ollama_base_url}[/red]")
            console.print("[dim]Lancez Ollama puis réessayez. Diagnostic : python main.py --check[/dim]")
            sys.exit(1)
    else:
        if not config.anthropic_api_key:
            console.print("[red]ANTHROPIC_API_KEY manquante dans votre fichier .env[/red]")
            console.print("[dim]Diagnostic : python main.py --check[/dim]")
            sys.exit(1)

    # Mode re-scoring : toutes les offres connues, sans scraper
    if args.rescore:
        if args.no_ai or not cv_texts:
            console.print("[red]--rescore nécessite l'IA et au moins un --cv (incompatible avec --no-ai).[/red]")
            sys.exit(1)
        rescore_known_offers(args, cv_texts)
        return

    # Critères par défaut : reproposer les derniers choix interactifs
    interactive = not (args.sectors or args.location.strip() or args.experience
                       or args.watch or args.rerun)
    use_defaults = False
    if interactive and (config.default_sectors or config.default_location or config.default_experience):
        console.print()
        use_defaults = Confirm.ask(
            f"[bold cyan]Reprendre vos derniers critères ?[/bold cyan] [dim]{_describe_defaults()}[/dim]",
            default=True,
        )

    # 3. Sélection des sources (une fois pour toutes les recherches)
    console.print("\n[bold]2. Sources de recherche[/bold]")
    if use_defaults and config.default_sources:
        sources = select_sources(config.default_sources)
    else:
        sources = select_sources(args.sources)

    # 4. Secteurs (une fois, modifiable en cours de session)
    console.print("\n[bold]3. Secteurs d'activité ciblés[/bold]")
    if use_defaults:
        sectors = select_sectors(config.default_sectors) if config.default_sectors else []
        if not config.default_sectors:
            console.print("[dim]Aucun filtre secteur appliqué.[/dim]")
    else:
        sectors = select_sectors(args.sectors)

    # 5. Localisation : pays → région → ville (modifiable en session avec 'v')
    console.print("\n[bold]4. Localisation[/bold]")
    if use_defaults:
        location = config.default_location
        config.country = config.default_country if config.default_country in COUNTRY_NAMES else "fr"
        console.print(
            f"[dim]Localisation : {escape(location) if location else 'sans filtre'}"
            f" ({COUNTRY_NAMES.get(config.country, 'France')})[/dim]"
        )
    elif args.location.strip() or args.watch or args.rerun:
        location = args.location.strip()
        config.country = args.country
        console.print(
            f"[dim]Localisation : {escape(location) if location else 'sans filtre'}"
            f" ({COUNTRY_NAMES.get(config.country, 'France')})[/dim]"
        )
    else:
        location = select_location()

    # 6. Niveau d'expérience (modifiable en session avec 'e')
    console.print("\n[bold]5. Niveau d'expérience recherché[/bold]")
    if use_defaults:
        experience = select_experience(config.default_experience) if config.default_experience else ""
        if not config.default_experience:
            console.print("[dim]Aucun filtre niveau d'expérience.[/dim]")
    else:
        experience = select_experience(args.experience)

    # Mémoriser les choix interactifs : reproposés au prochain lancement,
    # et utilisés comme défauts par l'interface web.
    if interactive and not use_defaults:
        _persist_defaults(sources, sectors, location, experience)

    # Tracker persistant : suit les offres vues / favoris / postulées / rejetées
    tracker = Tracker(Path(config.output_dir) / ".tracker.json")
    initial_stats = tracker.stats()
    if initial_stats["total"] > 0:
        console.print(
            f"[dim]Historique : {initial_stats['favorite']} favoris · "
            f"{initial_stats['applied']} postulées · "
            f"{initial_stats['rejected']} rejetées (filtrées par défaut)[/dim]"
        )

    # Apprentissage des préférences : les rejets passés pénalisent les offres similaires
    rejections = tracker.recent_rejections()
    if rejections:
        console.print(f"[dim]Préférences : {len(rejections)} rejet(s) récent(s) pris en compte dans le scoring.[/dim]")

    # Mots-clés éliminatoires : .env et CLI cumulés
    exclude = parse_exclude_keywords(config.exclude_keywords) + parse_exclude_keywords(args.exclude)
    if exclude:
        console.print(f"[dim]Mots-clés exclus : {escape(', '.join(exclude))}[/dim]")

    # Mode veille : boucle autonome, pas d'interaction
    if args.watch:
        if args.no_ai:
            console.print("[red]--watch est incompatible avec --no-ai (la veille score les nouvelles offres).[/red]")
            sys.exit(1)
        if not args.query.strip():
            console.print("[red]--watch nécessite --query (mode non interactif).[/red]")
            sys.exit(1)
        watch_loop(args, sources, sectors, cv_texts, tracker, exclude, location, experience)
        return

    # 5. Boucle de recherche
    # --global-search prend le dessus sur --query si les deux sont fournis ;
    # incompatible avec --no-ai (les requêtes globales sont générées par IA)
    if args.no_ai and args.global_search:
        console.print("[yellow]--global-search ignoré : incompatible avec --no-ai (requêtes générées par l'IA).[/yellow]")
        args.global_search = False
    first_query = "" if args.global_search else args.query.strip()
    pending_global = args.global_search
    console.print(
        "\n[dim]À tout moment : tapez [bold]x[/bold] pour quitter, "
        "[bold]s[/bold] pour changer les sources, "
        "[bold]f[/bold] pour changer les filtres secteur, "
        "[bold]v[/bold] pour changer la localisation, "
        "[bold]e[/bold] pour changer le niveau d'expérience, "
        "[bold]g[/bold] pour une recherche globale d'après vos CV.[/dim]"
    )

    while True:
        # Demande de la requête (ou requêtes générées par l'IA en mode global)
        queries: list[str] | None = None
        if pending_global:
            pending_global = False
            queries = _global_queries(cv_texts)
            if not queries:
                continue
            query = " · ".join(queries)
        elif first_query:
            query = first_query
            first_query = ""
        else:
            console.print("\n" + "─" * 60)
            raw = Prompt.ask(
                "[bold cyan]Nouvelle recherche[/bold cyan] [dim](x=quitter  s=sources  f=filtres  v=lieu  g=globale)[/dim]"
            ).strip()
            if raw.lower() == "x":
                console.print("[dim]Au revoir ![/dim]")
                break
            if raw.lower() == "s":
                sources = select_sources("")
                _persist_defaults(sources, sectors, location, experience)
                continue
            if raw.lower() == "f":
                sectors = select_sectors("")
                _persist_defaults(sources, sectors, location, experience)
                continue
            if raw.lower() == "v":
                location = select_location()
                _persist_defaults(sources, sectors, location, experience)
                continue
            if raw.lower() == "e":
                experience = select_experience("")
                _persist_defaults(sources, sectors, location, experience)
                continue
            if raw.lower() == "g":
                queries = _global_queries(cv_texts)
                if not queries:
                    continue
                query = " · ".join(queries)
            else:
                query = raw
                if not query:
                    continue

        # Scraping (une passe par requête en mode global, doublons fusionnés)
        where = f" à {escape(location)}" if location else ""
        console.print(f"\n[bold]Scraping :[/bold] « {escape(query)} »{where} sur {', '.join(sources)}")
        all_offers = []
        seen_keys: set[str] = set()
        for q in (queries or [query]):
            for offer in scrape_all(sources, q, location, args.max):
                key = offer.unique_key()
                if key not in seen_keys:
                    seen_keys.add(key)
                    all_offers.append(offer)

        if not all_offers:
            console.print(
                "[yellow]Aucune offre trouvée pour cette recherche.[/yellow] "
                "[dim]Essayez un autre intitulé ou de nouvelles sources.[/dim]"
            )
            continue  # ← retour à la demande de requête, pas de sys.exit

        # Filtrer les offres déjà postulées / rejetées (sauf si --include-seen)
        if not args.include_seen:
            before = len(all_offers)
            all_offers = tracker.filter_visible(all_offers)
            hidden = before - len(all_offers)
            if hidden:
                console.print(f"[dim]{hidden} offre(s) déjà traitée(s) filtrée(s) (utilisez --include-seen pour les voir).[/dim]")

        if not all_offers:
            console.print("[yellow]Toutes les offres trouvées sont déjà dans votre historique.[/yellow]")
            continue

        console.print(f"[bold]Total :[/bold] {len(all_offers)} offres collectées")

        # Mode test scraper (--no-ai) : aperçu brut, AUCUN appel IA — pour
        # ajuster requête/sources/filtres avant de consommer des tokens
        if args.no_ai:
            raw_path = save_raw_offers(all_offers, query)
            console.print(
                f"[bold yellow]Mode test scraper :[/bold yellow] aucune analyse IA. "
                f"[dim]Export brut : {escape(str(raw_path))}[/dim]"
            )
            browse_offers(all_offers, tracker)
            continue

        # Matching IA
        sector_label = f", secteurs : {', '.join(sectors)}" if sectors else ""
        console.print(f"[bold]Analyse[/bold] (score min : {args.min_score}/10{sector_label})")
        with Progress(SpinnerColumn(), TextColumn("[cyan]Analyse en cours..."), console=console) as progress:
            progress.add_task("", total=None)
            try:
                matched_offers = score_offers_multi(
                    cv_texts, all_offers, min_score=args.min_score, sectors=sectors,
                    exclude=exclude, experience_level=experience,
                    rejected_examples=rejections,
                )
            except Exception as e:
                if "AuthenticationError" in type(e).__name__:
                    console.print("[red]Clé ANTHROPIC_API_KEY invalide.[/red]")
                    sys.exit(1)
                console.print(f"[red]Erreur IA : {escape(str(e))}[/red]")
                continue

        if not matched_offers:
            console.print(
                f"[yellow]Aucune offre avec un score ≥ {args.min_score}/10.[/yellow] "
                f"[dim]Essayez un autre intitulé ou --min-score {args.min_score - 1}.[/dim]"
            )
            continue  # ← retour à la demande de requête

        # Affichage + export
        display_matches(matched_offers, tracker)
        save_results(matched_offers, query)

        # Historique : la session est rejouable (--rerun) et re-scorable (--rescore)
        _get_store().add_session(
            kind="scan",
            criteria={
                "query": query,
                "cv": ",".join(Path(p).name for p in args.cv),
                "country": config.country,
                "location": location,
                "sectors": _sector_keys(sectors),
                "experience": experience,
                "sources": sources,
                "min_score": args.min_score,
                "exclude": exclude,
            },
            offers=matched_offers,
            found=len(all_offers),
        )

        # Export Notion (opt-in via --notion)
        if args.notion:
            if notion_configured():
                export_to_notion(matched_offers)
            else:
                console.print("[yellow]--notion ignoré : NOTION_TOKEN et NOTION_DATABASE_ID manquants dans .env.[/yellow]")

        # Marquer comme "vues" en bulk (n'écrase pas favorite/applied)
        tracker.mark_many(matched_offers, "seen")

        # Mode scan : navigation interactive (lettres disponibles via 'm N')
        if args.scan:
            browse_offers(matched_offers, tracker, letter_cb=_make_letter_cb(cv_texts, tracker))
            console.print(f"[dim]{len(matched_offers)} offres exportées dans {config.output_dir}/[/dim]")
            continue  # ← propose une nouvelle recherche

        # Mode --no-letters
        if args.no_letters:
            console.print(f"[dim]Résultats exportés dans {config.output_dir}/[/dim]")
            continue

        # Mode complet : lettres de motivation
        console.print()
        if Confirm.ask("[bold cyan]Générer des lettres de motivation ?[/bold cyan]"):
            selected = select_offers(matched_offers)
            if selected:
                tone = args.tone or _ask_tone()
                applied_titles = [
                    str(e.get("title", "")) for e in tracker.list_by_status("applied") if e.get("title")
                ]
                console.print(f"\n[bold]Génération des lettres[/bold] ({len(selected)} offre(s), ton {tone})")
                generator = CoverLetterGenerator(
                    merge_cv_texts(cv_texts),
                    applied_history=applied_titles,
                    style_examples=_style_examples(),
                )
                generate_letters(selected, generator, tone=tone, store=_get_store())
                # Marquer auto comme "applied" : la lettre est prête à être envoyée
                tracker.mark_many(selected, "applied")
                console.print(f"[bold green]✓[/bold green] Lettres dans [cyan]{config.output_dir}/[/cyan]")
                console.print(f"[dim]→ {len(selected)} offre(s) marquée(s) comme postulée(s) dans l'historique.[/dim]")


if __name__ == "__main__":
    main()
