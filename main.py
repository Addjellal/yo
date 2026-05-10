#!/usr/bin/env python3
"""
Auto Job Application – recherche, matching IA et génération de lettres de motivation.

Usage:
    python main.py --cv mon_cv.pdf --query "développeur Python" --location "Paris"
    python main.py --cv mon_cv.pdf --query "data scientist" --sources ft,indeed,wttj
"""
import argparse
import json
import sys
import time
from pathlib import Path

from rich.console import Console
from rich.panel import Panel
from rich.progress import Progress, SpinnerColumn, TextColumn
from rich.prompt import Confirm, Prompt
from rich.table import Table
from rich import box

from config import config
from cv_parser import parse_cv
from scrapers import JobOffer, FranceTravailScraper, IndeedScraper, WTTJScraper, LinkedInScraper
from ai import JobMatcher, CoverLetterGenerator

console = Console()

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
        "--no-letters", action="store_true",
        help="Ne pas générer les lettres de motivation",
    )
    return parser.parse_args()


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
    table.add_column("Source", width=12)
    table.add_column("Pourquoi", min_width=30)

    for i, offer in enumerate(offers, 1):
        score = offer.match_score or 0
        score_str = f"[green]{score}/10[/green]" if score >= 8 else (
            f"[yellow]{score}/10[/yellow]" if score >= 6 else f"[red]{score}/10[/red]"
        )
        table.add_row(
            str(i),
            score_str,
            offer.title,
            offer.company,
            offer.location or "–",
            offer.source,
            offer.match_reasons or "–",
        )

    console.print(table)


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


def save_results(offers: list[JobOffer], query: str) -> None:
    out = Path(config.output_dir)
    out.mkdir(parents=True, exist_ok=True)
    safe_query = "".join(c if c.isalnum() else "_" for c in query)[:30]
    results_file = out / f"resultats_{safe_query}.json"

    data = [
        {
            "titre": o.title,
            "entreprise": o.company,
            "lieu": o.location,
            "source": o.source,
            "score": o.match_score,
            "raisons": o.match_reasons,
            "url": o.url,
            "salaire": o.salary,
            "contrat": o.contract_type,
        }
        for o in offers
    ]

    results_file.write_text(json.dumps(data, ensure_ascii=False, indent=2), encoding="utf-8")
    console.print(f"\n[dim]Résultats sauvegardés : {results_file}[/dim]")


def main():
    args = parse_args()

    console.print(Panel.fit(
        "[bold cyan]Auto Job Application[/bold cyan]\n"
        "Recherche · Matching IA · Lettres de motivation",
        border_style="cyan",
    ))

    # 1. Parsing CV
    console.print(f"\n[bold]1. Lecture du CV :[/bold] {args.cv}")
    try:
        cv_text = parse_cv(args.cv)
        console.print(f"[green]✓ CV parsé ({len(cv_text)} caractères)[/green]")
    except (FileNotFoundError, ValueError) as e:
        console.print(f"[red]Erreur CV : {e}[/red]")
        sys.exit(1)

    # 2. Scraping
    sources = [s.strip() for s in args.sources.split(",")]
    console.print(f"\n[bold]2. Scraping des offres[/bold] (sources : {', '.join(sources)})")
    all_offers = scrape_all(sources, args.query, args.location, args.max)

    if not all_offers:
        console.print("[red]Aucune offre trouvée. Vérifiez vos paramètres et identifiants API.[/red]")
        sys.exit(1)

    console.print(f"\n[bold]Total :[/bold] {len(all_offers)} offres collectées (doublons supprimés)")

    # 3. Matching IA
    console.print(f"\n[bold]3. Analyse de correspondance avec Claude[/bold] (score min : {args.min_score}/10)")
    with Progress(SpinnerColumn(), TextColumn("[cyan]Analyse en cours..."), console=console) as progress:
        progress.add_task("", total=None)
        try:
            matcher = JobMatcher(cv_text)
            matched_offers = matcher.score_offers(all_offers, min_score=args.min_score)
        except anthropic.AuthenticationError:
            console.print("[red]Clé ANTHROPIC_API_KEY invalide ou manquante.[/red]")
            sys.exit(1)

    if not matched_offers:
        console.print(f"[yellow]Aucune offre avec un score ≥ {args.min_score}/10. Essayez --min-score 5.[/yellow]")
        sys.exit(0)

    # 4. Affichage
    display_matches(matched_offers)
    save_results(matched_offers, args.query)

    # 5. Génération des lettres
    if args.no_letters:
        console.print("\n[dim]Génération des lettres désactivée (--no-letters).[/dim]")
        return

    selected = select_offers(matched_offers)
    if not selected:
        console.print("[dim]Aucune offre sélectionnée.[/dim]")
        return

    console.print(f"\n[bold]4. Génération des lettres de motivation[/bold] ({len(selected)} offre(s))")
    generator = CoverLetterGenerator(cv_text)
    generate_letters(selected, generator)

    console.print(f"\n[bold green]✓ Terminé ![/bold green] Lettres sauvegardées dans [cyan]{config.output_dir}/[/cyan]")
    console.print("[dim]Relisez et personnalisez chaque lettre avant envoi.[/dim]")


if __name__ == "__main__":
    import anthropic  # noqa: F401 – vérification import
    main()
