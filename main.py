#!/usr/bin/env python3
"""
Auto Job Application – recherche, matching IA et génération de lettres de motivation.

Usage:
    # Mode scan : parcourir les offres sans postuler
    python main.py --cv mon_cv.pdf --query "développeur Python" --scan

    # Mode complet : scan + génération de lettres de motivation
    python main.py --cv mon_cv.pdf --query "data scientist" --location "Paris"
"""
import argparse
import csv
import json
import sys
import time
from pathlib import Path

from rich.console import Console
from rich.panel import Panel
from rich.progress import Progress, SpinnerColumn, TextColumn
from rich.prompt import Confirm, Prompt
from rich.table import Table
from rich.columns import Columns
from rich.text import Text
from rich import box

from config import config
from cv_parser import parse_cv
from scrapers import JobOffer, FranceTravailScraper, IndeedScraper, WTTJScraper, LinkedInScraper
from ai import JobMatcher, CoverLetterGenerator

console = Console()

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
    "linkedin": ("LinkedIn", LinkedInScraper),
}


def parse_args():
    parser = argparse.ArgumentParser(
        description="Recherche et postule automatiquement aux offres d'emploi."
    )
    parser.add_argument("--cv", required=True, help="Chemin vers votre CV (PDF, DOCX ou TXT)")
    parser.add_argument("--query", required=True, help='Recherche ex: "développeur Python senior"')
    parser.add_argument("--location", default="", help='Localisation ex: "Paris" ou "Lyon"')
    parser.add_argument(
        "--sources",
        default="ft,indeed,wttj",
        help="Sources séparées par virgule : ft,indeed,wttj,linkedin (défaut: ft,indeed,wttj)",
    )
    parser.add_argument(
        "--max", type=int, default=config.max_jobs_per_source,
        help="Nombre max d'offres par source",
    )
    parser.add_argument(
        "--min-score", type=int, default=config.min_match_score,
        help="Score minimum de correspondance /10 (défaut: 6)",
    )
    parser.add_argument(
        "--sectors",
        default="",
        help=(
            "Secteurs cibles séparés par virgule (ex: tech,finance). "
            "Si absent, un sélecteur interactif s'affiche. "
            "Valeurs : " + ", ".join(k for k, _ in SECTORS)
        ),
    )
    parser.add_argument(
        "--scan", action="store_true",
        help="Mode scan uniquement : affiche et exporte les offres sans générer de lettres ni postuler",
    )
    parser.add_argument(
        "--no-letters", action="store_true",
        help="Ne pas générer les lettres de motivation (ignoré en mode --scan)",
    )
    return parser.parse_args()


def select_sectors(preselected: str = "") -> list[str]:
    """Interactive sector picker. Returns list of sector labels (empty = no filter)."""
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

    # Build display grid (2 columns)
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
        subtitle="[dim]Entrez les numéros, 'all' pour tous, ou Entrée pour ignorer[/dim]",
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


def scrape_all(sources: list[str], query: str, location: str, max_per_source: int) -> list[JobOffer]:
    all_offers: list[JobOffer] = []
    seen_keys: set[str] = set()

    for source_key in sources:
        if source_key not in SOURCE_MAP:
            console.print(f"[yellow]Source inconnue ignorée : {source_key}[/yellow]")
            continue

        source_name, scraper_cls = SOURCE_MAP[source_key]

        if source_key == "linkedin":
            console.print(
                "[yellow]⚠  LinkedIn : scraping contraire aux CGU, utilisation à vos risques.[/yellow]"
            )

        with Progress(SpinnerColumn(), TextColumn(f"[cyan]Scraping {source_name}..."), console=console) as progress:
            progress.add_task("", total=None)
            try:
                scraper = scraper_cls()
                offers = scraper.search(query, location, max_per_source)
                new_offers = []
                for o in offers:
                    key = o.unique_key()
                    if key not in seen_keys:
                        seen_keys.add(key)
                        new_offers.append(o)
                all_offers.extend(new_offers)
                console.print(f"[green]✓ {source_name} : {len(new_offers)} offres trouvées[/green]")
            except ValueError as e:
                console.print(f"[yellow]⚠  {source_name} désactivé : {e}[/yellow]")
            except Exception as e:
                console.print(f"[red]✗ {source_name} : erreur – {e}[/red]")

    return all_offers


def _score_color(score: int) -> str:
    if score >= 8:
        return "green"
    if score >= 6:
        return "yellow"
    return "red"


def display_matches(offers: list[JobOffer]) -> None:
    table = Table(
        title=f"\n{len(offers)} offres correspondantes",
        box=box.ROUNDED,
        show_lines=True,
        header_style="bold cyan",
    )
    table.add_column("#", style="dim", width=4)
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
        table.add_row(
            str(i),
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


def browse_offers(offers: list[JobOffer]) -> None:
    """Interactive detail viewer for scan mode."""
    console.print(
        "\n[dim]Tapez un [bold]numéro[/bold] pour voir le détail d'une offre, "
        "[bold]'l'[/bold] pour lister à nouveau, ou [bold]Entrée[/bold] pour quitter.[/dim]"
    )

    while True:
        choice = Prompt.ask("[bold cyan]Offre #[/bold cyan]", default="").strip().lower()
        if choice == "":
            break
        if choice == "l":
            display_matches(offers)
            continue
        try:
            idx = int(choice) - 1
            if not (0 <= idx < len(offers)):
                console.print(f"[red]Numéro hors plage (1–{len(offers)}).[/red]")
                continue
            _show_detail(offers[idx])
        except ValueError:
            console.print("[red]Entrez un numéro, 'l' ou Entrée.[/red]")


def _show_detail(offer: JobOffer) -> None:
    score = offer.match_score or 0
    color = _score_color(score)

    meta_lines = [
        f"[bold]Entreprise :[/bold] {offer.company}",
        f"[bold]Lieu :[/bold]       {offer.location or '–'}",
        f"[bold]Contrat :[/bold]    {offer.contract_type or '–'}",
        f"[bold]Salaire :[/bold]    {offer.salary or '–'}",
        f"[bold]Source :[/bold]     {offer.source}",
        f"[bold]Score :[/bold]      [{color}]{score}/10[/{color}]  {offer.match_reasons or ''}",
        f"[bold]URL :[/bold]        [link={offer.url}]{offer.url}[/link]",
    ]
    meta = "\n".join(meta_lines)

    desc = (offer.description or "Pas de description disponible.").strip()
    if len(desc) > 1500:
        desc = desc[:1500] + "\n[dim]… (tronqué)[/dim]"

    console.print(Panel(
        meta + "\n\n" + desc,
        title=f"[bold cyan]{offer.title}[/bold cyan]",
        border_style=color,
        padding=(1, 2),
    ))


def select_offers(offers: list[JobOffer]) -> list[JobOffer]:
    console.print("\n[bold]Sélectionnez les offres pour lesquelles générer une lettre de motivation.[/bold]")
    console.print("Entrez les numéros séparés par des virgules, [cyan]'all'[/cyan] pour tout, ou [cyan]'q'[/cyan] pour quitter.")

    while True:
        choice = Prompt.ask("[bold cyan]Votre sélection[/bold cyan]").strip().lower()
        if choice == "q":
            return []
        if choice == "all":
            return offers
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
                    console.print(f"  [dim]PDF sauvegardé : {pdf_path}[/dim]")

            except Exception as e:
                console.print(f"[red]Erreur génération pour {offer.title} : {e}[/red]")

        time.sleep(0.5)


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
            "lieu": o.location,
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
    console.print(f"[dim]CSV  : {csv_path}  (ouvrable dans Excel / Google Sheets)[/dim]")
    return json_path, csv_path


def main():
    args = parse_args()
    scan_only = args.scan or args.no_letters

    mode_label = "[bold yellow]MODE SCAN[/bold yellow]" if args.scan else "Recherche · Matching IA · Lettres de motivation"
    console.print(Panel.fit(
        f"[bold cyan]Auto Job Application[/bold cyan]\n{mode_label}",
        border_style="cyan",
    ))
    if args.scan:
        console.print("[dim]Mode scan : aucune candidature ne sera envoyée.[/dim]")

    # 1. Parsing CV
    console.print(f"\n[bold]1. Lecture du CV :[/bold] {args.cv}")
    try:
        cv_text = parse_cv(args.cv)
        console.print(f"[green]✓ CV parsé ({len(cv_text)} caractères)[/green]")
    except (FileNotFoundError, ValueError) as e:
        console.print(f"[red]Erreur CV : {e}[/red]")
        sys.exit(1)

    # 2. Sélection des secteurs
    console.print("\n[bold]2. Secteurs d'activité ciblés[/bold]")
    sectors = select_sectors(args.sectors)

    # 3. Scraping
    sources = [s.strip() for s in args.sources.split(",")]
    console.print(f"\n[bold]3. Scraping des offres[/bold] (sources : {', '.join(sources)})")
    all_offers = scrape_all(sources, args.query, args.location, args.max)

    if not all_offers:
        console.print("[red]Aucune offre trouvée. Vérifiez vos paramètres et identifiants API.[/red]")
        sys.exit(1)

    console.print(f"\n[bold]Total :[/bold] {len(all_offers)} offres collectées (doublons supprimés)")

    # 4. Matching IA
    sector_label = f", secteurs : {', '.join(sectors)}" if sectors else ""
    console.print(f"\n[bold]4. Analyse de correspondance avec Claude[/bold] (score min : {args.min_score}/10{sector_label})")
    with Progress(SpinnerColumn(), TextColumn("[cyan]Analyse en cours..."), console=console) as progress:
        progress.add_task("", total=None)
        try:
            matcher = JobMatcher(cv_text)
            matched_offers = matcher.score_offers(all_offers, min_score=args.min_score, sectors=sectors)
        except anthropic.AuthenticationError:
            console.print("[red]Clé ANTHROPIC_API_KEY invalide ou manquante.[/red]")
            sys.exit(1)

    if not matched_offers:
        console.print(f"[yellow]Aucune offre avec un score ≥ {args.min_score}/10. Essayez --min-score 5.[/yellow]")
        sys.exit(0)

    # 5. Affichage + export
    display_matches(matched_offers)
    save_results(matched_offers, args.query)

    # 6a. Mode scan : navigation interactive, puis sortie
    if scan_only:
        browse_offers(matched_offers)
        console.print(f"\n[bold green]✓ Scan terminé.[/bold green] {len(matched_offers)} offres exportées dans [cyan]{config.output_dir}/[/cyan]")
        return

    # 6b. Mode complet : génération des lettres de motivation
    console.print()
    if not Confirm.ask("[bold cyan]Générer des lettres de motivation pour certaines offres ?[/bold cyan]"):
        console.print("[dim]Aucune lettre générée. Résultats disponibles dans le dossier output/.[/dim]")
        return

    selected = select_offers(matched_offers)
    if not selected:
        console.print("[dim]Aucune offre sélectionnée.[/dim]")
        return

    console.print(f"\n[bold]Génération des lettres de motivation[/bold] ({len(selected)} offre(s))")
    generator = CoverLetterGenerator(cv_text)
    generate_letters(selected, generator)

    console.print(f"\n[bold green]✓ Terminé ![/bold green] Lettres sauvegardées dans [cyan]{config.output_dir}/[/cyan]")
    console.print("[dim]Relisez et personnalisez chaque lettre avant envoi.[/dim]")


if __name__ == "__main__":
    import anthropic  # noqa: F401 – vérification import
    main()
