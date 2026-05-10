"""
Scraper Apec.fr — site n°1 pour les cadres en France.

Utilise leur API publique de recherche d'offres :
    POST https://www.apec.fr/cms/webservices/rechercheOffre

Aucune authentification requise.
"""
import time
import requests

from .base import BaseScraper, JobOffer
from config import config
from utils import console

API_URL = "https://www.apec.fr/cms/webservices/rechercheOffre"
DETAIL_URL_TEMPLATE = "https://www.apec.fr/candidat/recherche-emploi.html/emploi/detail-offre/{offer_id}"

HEADERS = {
    "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36",
    "Accept": "application/json, text/plain, */*",
    "Accept-Language": "fr-FR,fr;q=0.9",
    "Content-Type": "application/json",
    "Referer": "https://www.apec.fr/candidat/recherche-emploi.html",
    "Origin": "https://www.apec.fr",
}


class ApecScraper(BaseScraper):
    source_name = "Apec"

    def search(self, query: str, location: str = "", max_results: int = 50) -> list[JobOffer]:
        offers: list[JobOffer] = []
        page = 0
        page_size = 20
        session = requests.Session()
        session.headers.update(HEADERS)

        while len(offers) < max_results:
            payload = {
                "motsCles": query,
                "lieux": [location] if location else [],
                "typesContrat": [],
                "typesConvention": [],
                "niveauxExperience": [],
                "fonctions": [],
                "secteursActivite": [],
                "salaireMinimum": 0,
                "salaireMaximum": 200,
                "pagination": {"range": page_size, "startIndex": page * page_size},
                "sorts": [{"type": "DATE", "direction": "DESCENDING"}],
                "activeFiltre": "ACTIF",
            }
            try:
                resp = session.post(API_URL, json=payload, timeout=15)
                resp.raise_for_status()
                data = resp.json()
            except (requests.RequestException, ValueError) as e:
                console.print(f"[yellow][Apec] Erreur réseau : {e}[/yellow]")
                break

            results = data.get("resultats", [])
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
            offer_id = str(item.get("numeroOffre") or item.get("id") or "")
            title = item.get("intitule") or item.get("intituleOffre") or ""
            if not title or not offer_id:
                return None

            company = item.get("nomCommercial") or item.get("entreprise") or "N/A"
            city = item.get("lieuTexte") or item.get("lieuPrincipal") or ""
            description = item.get("texteAccroche") or item.get("descriptifPoste") or ""
            contract = item.get("typeContrat") or ""
            salary = item.get("salaireTexte") or None

            url = DETAIL_URL_TEMPLATE.format(offer_id=offer_id)

            return JobOffer(
                id=f"apec_{offer_id}",
                title=title.strip(),
                company=company.strip() if company else "N/A",
                location=city.strip(),
                description=description.strip(),
                url=url,
                apply_url=url,
                source=self.source_name,
                salary=salary,
                contract_type=contract,
            )
        except Exception:
            return None
