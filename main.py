#!/usr/bin/env python3
"""
Auto Job Application – recherche, matching IA et génération de lettres de motivation.

Usage rapide :
    python main.py --check                          # Vérifier l'environnement
    python main.py --cv cv.pdf --scan               # Scanner sans postuler
    python main.py --cv cv.pdf --query "dev Python" # Mode complet
"""
import argparse
import csv
import importlib.util
import json
import sys
import time
import webbrowser
from concurrent.futures import ThreadPoolExecutor, as_completed
from pathlib import Path

from rich.console import Console
from rich.panel import Panel
from rich.progress import Progress, SpinnerColumn, TextColumn
from rich.prompt import Confirm, Prompt
from rich.table import Table
from rich import box

from config import config, save_to_env
from cv_parser import parse_cv
from scrapers import (
    JobOffer,
    FranceTravailScraper,
    IndeedScraper,
    WTTJScraper,
    LinkedInScraper,
    ApecScraper,
    AdzunaScraper,
)
from ai import JobMatcher, CoverLetterGenerator
from tracker import Tracker

console = Console()

# Marqueurs visuels pour les statuts de tracking
STATUS_BADGE = {
    "new":      "",
    "seen":     "[dim]·[/dim]",
    "favorite": "[yellow]★[/yellow]",
    "applied":  "[green]✓[/green]",
    "rejected": "[red]✗[/red]",
}

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
            else f"  {ko}  ANTHROPIC_API_KEY  [red]MANQUANTE[/red]  → platform.anthropic.com"
        )
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
        ("playwright",    "playwright",     False, "Scraping LinkedIn — pip install playwright && playwright install chromium"),
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
            console.print(f"[yellow]Secteurs inconnus ignorés : {', '.join(unknown)}[/yellow]")
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


def _prompt_linkedin_creds() -> bool:
    """Ask for LinkedIn credentials. Returns True if provided."""
    console.print(
        "\n[yellow]⚠  Le scraping LinkedIn est contraire à leurs CGU.[/yellow]\n"
        "[dim]Playwright doit être installé : pip install playwright && playwright install chromium[/dim]"
    )
    if not Confirm.ask("  Continuer quand même ?", default=False):
        return False
    email = Prompt.ask("  Email LinkedIn").strip()
    password = Prompt.ask("  Mot de passe LinkedIn", password=True).strip()
    if not email or not password:
        console.print("[yellow]Identifiants vides — LinkedIn ignoré.[/yellow]")
        return False
    config.linkedin_email = email
    config.linkedin_password = password
    if Confirm.ask("  Sauvegarder dans .env ?", default=False):
        save_to_env("LINKEDIN_EMAIL", email)
        save_to_env("LINKEDIN_PASSWORD", password)
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
        "auth": True,
        "note": "⚠  Contraire aux CGU LinkedIn — à vos risques",
        "configured": lambda: bool(config.linkedin_email and config.linkedin_password),
        "prompt": _prompt_linkedin_creds,
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
            console.print(f"[yellow]Sources inconnues ignorées : {', '.join(unknown)}[/yellow]")
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
            console.print(f"[yellow]Source inconnue ignorée : {s}[/yellow]")

    if not valid_sources:
        return []

    if "linkedin" in valid_sources:
        console.print("[yellow]⚠  LinkedIn : scraping contraire aux CGU, utilisation à vos risques.[/yellow]")

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
                    console.print(f"[{color}]⚠  {source_name} : {error}[/{color}]")
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
        table.add_row(
            str(i),
            badge,
            f"[{color}]{score}/10[/{color}]",
            offer.title,
            offer.company,
            offer.location or "–",
            offer.contract_type or "–",
            offer.salary or "–",
            offer.source,
            offer.match_reasons or "–",
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


def browse_offers(offers: list[JobOffer], tracker: Tracker | None = None) -> None:
    """Navigation interactive après un scan."""
    console.print(
        "\n[dim]Commandes : [bold]N[/bold] détail · [bold]o N[/bold] ouvrir · "
        "[bold]f N[/bold] favori · [bold]a N[/bold] postulé · [bold]r N[/bold] rejeter · "
        "[bold]l[/bold] relister · [bold]Entrée[/bold] quitter[/dim]"
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

        # Commandes à 2 lettres : "o N", "f N", "a N", "r N"
        cmd, _, arg = choice.partition(" ")
        if cmd in ("o", "f", "a", "r") and arg:
            indices = _parse_indices(arg, len(offers))
            if not indices:
                console.print(f"[red]Numéros invalides (1–{len(offers)}).[/red]")
                continue
            targets = [offers[i] for i in indices]
            if cmd == "o":
                for offer in targets:
                    webbrowser.open(offer.url)
                    console.print(f"[dim]Ouverture : {offer.url}[/dim]")
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
            console.print("[red]Commande inconnue. Tapez un numéro, 'o/f/a/r N', 'l' ou Entrée.[/red]")


def _show_detail(offer: JobOffer) -> None:
    score = offer.match_score or 0
    color = _score_color(score)

    meta = "\n".join([
        f"[bold]Entreprise :[/bold] {offer.company}",
        f"[bold]Lieu :[/bold]       {offer.location or '–'}",
        f"[bold]Contrat :[/bold]    {offer.contract_type or '–'}",
        f"[bold]Salaire :[/bold]    {offer.salary or '–'}",
        f"[bold]Source :[/bold]     {offer.source}",
        f"[bold]Score :[/bold]      [{color}]{score}/10[/{color}]  {offer.match_reasons or ''}",
        f"[bold]URL :[/bold]        [link={offer.url}]{offer.url}[/link]",
    ])

    desc = (offer.description or "Pas de description disponible.").strip()
    if len(desc) > 1500:
        desc = desc[:1500] + "\n[dim]… (tronqué — ouvrez l'URL pour la suite)[/dim]"

    console.print(Panel(
        meta + "\n\n" + desc,
        title=f"[bold cyan]{offer.title}[/bold cyan]",
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


def generate_letters(offers: list[JobOffer], generator: CoverLetterGenerator) -> None:
    for offer in offers:
        with Progress(SpinnerColumn(), TextColumn(f"[cyan]Génération : {offer.title} @ {offer.company}..."), console=console) as progress:
            progress.add_task("", total=None)
            try:
                letter = generator.generate(offer)
                txt_path, pdf_path = generator.save(offer, letter)

                console.print(Panel(
                    letter,
                    title=f"[bold green]{offer.title} – {offer.company}[/bold green]",
                    subtitle=f"[dim]{txt_path}[/dim]",
                    expand=False,
                ))

                if pdf_path.exists():
                    console.print(f"  [dim]PDF : {pdf_path}[/dim]")

            except Exception as e:
                console.print(f"[red]Erreur génération pour {offer.title} : {e}[/red]")

        time.sleep(0.5)


# ─── Export ───────────────────────────────────────────────────────────────────

def save_results(offers: list[JobOffer], query: str) -> tuple[Path, Path]:
    out = Path(config.output_dir)
    out.mkdir(parents=True, exist_ok=True)
    safe_query = "".join(c if c.isalnum() else "_" for c in query)[:30]

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
        writer.writerows(rows)

    console.print(f"\n[dim]JSON : {json_path}[/dim]")
    console.print(f"[dim]CSV  : {csv_path}  (Excel / Google Sheets)[/dim]")
    return json_path, csv_path


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
            table.add_row(date, entry["title"], entry["company"], entry["source"])
        console.print(table)

    favs = tracker.list_by_status("favorite")
    if favs:
        table = Table(title="\nFavoris", box=box.ROUNDED, header_style="bold yellow")
        table.add_column("Poste", min_width=25)
        table.add_column("Entreprise", min_width=18)
        table.add_column("Source", width=10)
        table.add_column("URL", overflow="fold")
        for entry in favs[:20]:
            table.add_row(entry["title"], entry["company"], entry["source"], entry["url"])
        console.print(table)


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
            "  python main.py --cv cv.pdf --scan --include-seen # Réafficher l'historique\n"
        ),
    )
    parser.add_argument("--check", action="store_true", help="Vérifier l'environnement et quitter")
    parser.add_argument("--stats", action="store_true", help="Afficher l'historique des candidatures et favoris")
    parser.add_argument("--cv", help="Chemin vers votre CV (PDF, DOCX ou TXT)")
    parser.add_argument("--query", default="", help='Recherche ex: "développeur Python senior" (optionnel : demandé interactivement si absent)')
    parser.add_argument("--location", default="", help='Localisation ex: "Paris"')
    parser.add_argument(
        "--sources", default="apec,adzuna,indeed,wttj",
        help="Sources : ft,indeed,wttj,apec,adzuna,linkedin (défaut: apec,adzuna,indeed,wttj)",
    )
    parser.add_argument("--max", type=int, default=config.max_jobs_per_source, help="Max offres par source")
    parser.add_argument("--min-score", type=int, default=config.min_match_score, help="Score minimum /10 (défaut: 6)")
    parser.add_argument(
        "--sectors", default="",
        help="Secteurs cibles : " + ", ".join(k for k, _ in SECTORS),
    )
    parser.add_argument("--scan", action="store_true", help="Scan uniquement : affiche et exporte sans générer de lettres")
    parser.add_argument("--no-letters", action="store_true", help="Analyse complète mais sans étape de génération de lettres")
    parser.add_argument(
        "--include-seen", action="store_true",
        help="Inclure les offres déjà postulées ou rejetées dans les résultats",
    )
    return parser.parse_args()


def main():
    args = parse_args()

    # Mode vérification
    if args.check:
        check_setup()
        return

    # Mode stats
    if args.stats:
        show_stats()
        return

    console.print(Panel.fit(
        "[bold cyan]Auto Job Application[/bold cyan]\n"
        + ("[bold yellow]MODE SCAN — aucune candidature ne sera envoyée[/bold yellow]" if args.scan
           else "Recherche · Matching IA · Lettres de motivation"),
        border_style="cyan",
    ))

    # 1. CV (obligatoire sauf --check)
    if not args.cv:
        console.print("[red]--cv est requis. Exemple : python main.py --cv mon_cv.pdf --scan[/red]")
        console.print("[dim]Conseil : lancez d'abord  python main.py --check  pour vérifier votre configuration.[/dim]")
        sys.exit(1)

    console.print(f"\n[bold]1. Lecture du CV :[/bold] {args.cv}")
    try:
        cv_text = parse_cv(args.cv)
        console.print(f"[green]✓ CV parsé ({len(cv_text)} caractères)[/green]")
    except (FileNotFoundError, ValueError) as e:
        console.print(f"[red]Erreur CV : {e}[/red]")
        sys.exit(1)

    # 2. Vérification provider IA
    if config.provider == "ollama":
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

    # 3. Sélection des sources (une fois pour toutes les recherches)
    console.print("\n[bold]2. Sources de recherche[/bold]")
    sources = select_sources(args.sources)

    # 4. Secteurs (une fois, modifiable en cours de session)
    console.print("\n[bold]3. Secteurs d'activité ciblés[/bold]")
    sectors = select_sectors(args.sectors)

    # Matcher initialisé une seule fois (CV en mémoire)
    matcher = JobMatcher(cv_text)

    # Tracker persistant : suit les offres vues / favoris / postulées / rejetées
    tracker = Tracker(Path(config.output_dir) / ".tracker.json")
    initial_stats = tracker.stats()
    if initial_stats["total"] > 0:
        console.print(
            f"[dim]Historique : {initial_stats['favorite']} favoris · "
            f"{initial_stats['applied']} postulées · "
            f"{initial_stats['rejected']} rejetées (filtrées par défaut)[/dim]"
        )

    # 5. Boucle de recherche
    first_query = args.query.strip()
    console.print(
        "\n[dim]À tout moment : tapez [bold]x[/bold] pour quitter, "
        "[bold]s[/bold] pour changer les sources, "
        "[bold]f[/bold] pour changer les filtres secteur.[/dim]"
    )

    while True:
        # Demande de la requête
        if first_query:
            query = first_query
            first_query = ""
        else:
            console.print("\n" + "─" * 60)
            raw = Prompt.ask(
                "[bold cyan]Nouvelle recherche[/bold cyan] [dim](x=quitter  s=sources  f=filtres)[/dim]"
            ).strip()
            if raw.lower() == "x":
                console.print("[dim]Au revoir ![/dim]")
                break
            if raw.lower() == "s":
                sources = select_sources("")
                continue
            if raw.lower() == "f":
                sectors = select_sectors("")
                continue
            query = raw
            if not query:
                continue

        # Scraping
        console.print(f"\n[bold]Scraping :[/bold] « {query} » sur {', '.join(sources)}")
        all_offers = scrape_all(sources, query, args.location, args.max)

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

        # Matching IA
        sector_label = f", secteurs : {', '.join(sectors)}" if sectors else ""
        console.print(f"[bold]Analyse[/bold] (score min : {args.min_score}/10{sector_label})")
        with Progress(SpinnerColumn(), TextColumn("[cyan]Analyse en cours..."), console=console) as progress:
            progress.add_task("", total=None)
            try:
                matched_offers = matcher.score_offers(all_offers, min_score=args.min_score, sectors=sectors)
            except Exception as e:
                if "AuthenticationError" in type(e).__name__:
                    console.print("[red]Clé ANTHROPIC_API_KEY invalide.[/red]")
                    sys.exit(1)
                console.print(f"[red]Erreur IA : {e}[/red]")
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

        # Marquer comme "vues" en bulk (n'écrase pas favorite/applied)
        tracker.mark_many(matched_offers, "seen")

        # Mode scan : navigation interactive
        if args.scan:
            browse_offers(matched_offers, tracker)
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
                console.print(f"\n[bold]Génération des lettres[/bold] ({len(selected)} offre(s))")
                generator = CoverLetterGenerator(cv_text)
                generate_letters(selected, generator)
                # Marquer auto comme "applied" : la lettre est prête à être envoyée
                tracker.mark_many(selected, "applied")
                console.print(f"[bold green]✓[/bold green] Lettres dans [cyan]{config.output_dir}/[/cyan]")
                console.print(f"[dim]→ {len(selected)} offre(s) marquée(s) comme postulée(s) dans l'historique.[/dim]")


if __name__ == "__main__":
    main()
