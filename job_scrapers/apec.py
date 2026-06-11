"""
Scraper Apec.fr — site n°1 pour les cadres en France.

Utilise leur API publique de recherche d'offres.
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


def _build_payload(query: str, start: int, page_size: int) -> dict:
    """Payload correct pour l'API APEC (format validé)."""
    return {
        "typeOffre": [],
        "motsCles": query,
        "lieu": [],
        "fonctions": [],
        "secteurs": [],
        "niveauFormation": [],
        "experience": [],
        "statutPoste": [],
        "salaire": None,
        "nombreSalaries": [],
        "tri": 0,
        "indiceDebut": start,
        "nombreResultats": page_size,
        "accesHand": False,
    }


class ApecScraper(BaseScraper):
    source_name = "Apec"

    def search(self, query: str, location: str = "", max_results: int = 50) -> list[JobOffer]:
        # APEC retourne 500 sur les requêtes trop courtes ou les mots tronqués
        if len(query.strip()) < 3:
            console.print(f"[yellow][Apec] Requête trop courte ({query!r}), ignorée.[/yellow]")
            return []

        offers: list[JobOffer] = []
        page_size = 20
        start = 0
        session = requests.Session()
        session.headers.update(HEADERS)

        while len(offers) < max_results:
            payload = _build_payload(query, start, page_size)
            try:
                resp = session.post(API_URL, json=payload, timeout=15)
                if resp.status_code == 400:
                    console.print(f"[yellow][Apec] Payload rejeté (400). Réponse : {resp.text[:200]}[/yellow]")
                    break
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
            start += page_size
            time.sleep(config.request_delay)

        return offers

    def _parse_item(self, item: dict) -> JobOffer | None:
        try:
            offer_id = str(item.get("numeroOffre") or item.get("id") or "")
            title = item.get("intitule") or item.get("intituleOffre") or ""
            if not title or not offer_id:
                return None

            entreprise = item.get("employeur") or {}
            if isinstance(entreprise, dict):
                company = entreprise.get("nom") or item.get("nomCommercial") or "N/A"
            else:
                company = str(entreprise) or item.get("nomCommercial") or "N/A"

            # localisation
            lieu = item.get("lieux") or item.get("lieu") or []
            if isinstance(lieu, list) and lieu:
                loc = lieu[0]
                city = loc.get("libelle") or loc.get("label") or ""
            else:
                city = item.get("lieuTexte") or ""

            description = item.get("texteAccroche") or item.get("descriptifPoste") or ""

            # contrat
            contrat_obj = item.get("typeContrat") or {}
            contract = contrat_obj.get("libelle") if isinstance(contrat_obj, dict) else str(contrat_obj or "")

            # salaire
            sal = item.get("salaire") or {}
            salary = sal.get("libelle") if isinstance(sal, dict) else None

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
