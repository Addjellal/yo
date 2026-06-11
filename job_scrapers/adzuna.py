"""
Scraper Adzuna — agrégateur de millions d'offres d'emploi via leur API publique.

API gratuite (1 000 appels/mois) : https://developer.adzuna.com
Inscription rapide, sans carte bancaire.
"""
import time
import requests

from .base import BaseScraper, JobOffer
from config import config
from utils import console

API_URL = "https://api.adzuna.com/v1/api/jobs/fr/search/{page}"
REGISTER_URL = "https://developer.adzuna.com"


class AdzunaScraper(BaseScraper):
    source_name = "Adzuna"

    def __init__(self):
        if not config.adzuna_app_id or not config.adzuna_app_key:
            raise ValueError(
                "ADZUNA_APP_ID et ADZUNA_APP_KEY manquants.\n"
                f"Inscription gratuite (sans CB) : {REGISTER_URL}"
            )

    def search(self, query: str, location: str = "", max_results: int = 50) -> list[JobOffer]:
        offers: list[JobOffer] = []
        page = 1
        page_size = min(50, max_results)
        session = requests.Session()
        session.headers["User-Agent"] = (
            "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36"
        )

        while len(offers) < max_results:
            params: dict = {
                "app_id": config.adzuna_app_id,
                "app_key": config.adzuna_app_key,
                "results_per_page": page_size,
                "what": query,
                "sort_by": "date",
                "content-type": "application/json",
            }
            if location:
                params["where"] = location

            try:
                resp = session.get(
                    API_URL.format(page=page),
                    params=params,
                    timeout=15,
                )
                resp.raise_for_status()
                data = resp.json()
            except requests.RequestException as e:
                console.print(f"[yellow][Adzuna] Erreur réseau : {e}[/yellow]")
                break
            except ValueError as e:
                console.print(f"[yellow][Adzuna] Erreur JSON : {e}[/yellow]")
                break

            results = data.get("results", [])
            if not results:
                break

            for item in results:
                job = self._parse_item(item)
                if job:
                    offers.append(job)
                if len(offers) >= max_results:
                    break

            if len(results) < page_size:
                break
            page += 1
            time.sleep(config.request_delay)

        return offers

    def _parse_item(self, item: dict) -> JobOffer | None:
        try:
            job_id = str(item.get("id", ""))
            title = (item.get("title") or "").strip()
            if not title or not job_id:
                return None

            company = item.get("company", {}).get("display_name", "N/A")
            loc_obj = item.get("location", {})
            location = loc_obj.get("display_name", "")
            description = (item.get("description") or "").strip()
            url = item.get("redirect_url", "")

            salary_min = item.get("salary_min")
            salary_max = item.get("salary_max")
            salary = None
            if salary_min and salary_max:
                salary = f"{int(salary_min):,}–{int(salary_max):,} €/an".replace(",", " ")
            elif salary_min:
                salary = f"À partir de {int(salary_min):,} €/an".replace(",", " ")

            contract = item.get("contract_time") or item.get("contract_type") or ""

            return JobOffer(
                id=f"adzuna_{job_id}",
                title=title,
                company=company,
                location=location,
                description=description,
                url=url,
                apply_url=url,
                source=self.source_name,
                salary=salary,
                contract_type=contract,
            )
        except Exception:
            return None
