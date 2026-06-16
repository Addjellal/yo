"""
Scraper Welcome to the Jungle.

WTTJ charge ses offres côté client via Algolia (le HTML ne contient plus les
annonces — d'où « 0 offre » avec l'ancien parsing de __NEXT_DATA__). On interroge
donc directement l'API de recherche Algolia, comme le fait le site lui-même.

Les identifiants Algolia (App ID + clé publique de recherche) sont ceux,
publics, embarqués dans le frontend de WTTJ. Ils tournent de temps en temps :
on peut les surcharger sans toucher au code via les variables d'environnement
WTTJ_ALGOLIA_APP_ID / WTTJ_ALGOLIA_API_KEY / WTTJ_ALGOLIA_INDEX.
Pour les rafraîchir : ouvrir welcometothejungle.com → DevTools → Réseau →
filtrer « algolia.net », lire les en-têtes x-algolia-application-id et
x-algolia-api-key d'une requête /queries.
"""
import json
import os
import time
import urllib.parse

import requests

from .base import BaseScraper, JobOffer, MAX_RESPONSE_BYTES, fetch_with_retry
from config import config
from app_utils import console

MAX_PAGES = 20
HITS_PER_PAGE = 20
BASE_URL = "https://www.welcometothejungle.com"

# Identifiants publics de recherche Algolia de WTTJ (surchargés par l'env).
ALGOLIA_APP_ID = os.environ.get("WTTJ_ALGOLIA_APP_ID", "CSEKHVMS53").strip()
ALGOLIA_API_KEY = os.environ.get(
    "WTTJ_ALGOLIA_API_KEY", "02d2eef2400a39e26d764e2b50522f31"
).strip()
ALGOLIA_INDEX = os.environ.get(
    "WTTJ_ALGOLIA_INDEX", "wttj_jobs_production_published_at_desc"
).strip()


def _algolia_url() -> str:
    return f"https://{ALGOLIA_APP_ID.lower()}-dsn.algolia.net/1/indexes/*/queries"


class WTTJScraper(BaseScraper):
    source_name = "Welcome to the Jungle"

    def search(self, query: str, location: str = "", max_results: int = 50) -> list[JobOffer]:
        if not (ALGOLIA_APP_ID and ALGOLIA_API_KEY):
            return []

        offers: list[JobOffer] = []
        seen: set[str] = set()
        session = requests.Session()
        session.headers.update({
            "X-Algolia-Application-Id": ALGOLIA_APP_ID,
            "X-Algolia-API-Key": ALGOLIA_API_KEY,
            "Content-Type": "application/json",
            "Accept": "application/json",
        })
        # La recherche géographique précise exige des coordonnées ; à défaut, on
        # ajoute le lieu aux mots-clés (suffisant pour une ville/région nommée).
        full_query = f"{query} {location}".strip() if location else query

        page = 0
        while len(offers) < max_results and page < MAX_PAGES:
            params = urllib.parse.urlencode({
                "query": full_query,
                "hitsPerPage": HITS_PER_PAGE,
                "page": page,
            })
            body = json.dumps({"requests": [{"indexName": ALGOLIA_INDEX, "params": params}]})
            try:
                resp = fetch_with_retry(
                    lambda: session.post(_algolia_url(), data=body, timeout=15),
                    source="WTTJ",
                    log=lambda m: console.print(f"[dim]{m}[/dim]"),
                )
                if resp.status_code != 200:
                    console.print(
                        f"[yellow]WTTJ : Algolia a répondu HTTP {resp.status_code} "
                        f"(identifiants peut-être périmés) — {resp.text[:200]}[/yellow]"
                    )
                    break
                if len(resp.content) > MAX_RESPONSE_BYTES:
                    break
                data = resp.json()
            except (requests.RequestException, ValueError) as e:
                console.print(f"[yellow]WTTJ : requête Algolia échouée — {e}[/yellow]")
                break

            res_msg = data.get("message")
            if res_msg:  # erreur Algolia (index inconnu, clé invalide…)
                console.print(f"[yellow]WTTJ : Algolia a renvoyé une erreur — {res_msg}[/yellow]")
                break
            results = (data.get("results") or [{}])[0]
            hits = results.get("hits") or []
            if not hits:
                if page == 0:
                    console.print(
                        f"[dim]WTTJ : 0 résultat (nbHits={results.get('nbHits')})[/dim]"
                    )
                break

            before = len(offers)
            for item in hits:
                job = self._parse_item(item)
                if job and job.unique_key() not in seen:
                    seen.add(job.unique_key())
                    offers.append(job)
                if len(offers) >= max_results:
                    break

            nb_pages = results.get("nbPages", page + 1)
            if len(offers) == before or page + 1 >= nb_pages:
                break
            page += 1
            time.sleep(config.request_delay)

        return offers

    def _parse_item(self, item: dict) -> JobOffer | None:
        try:
            job_id = str(item.get("id", item.get("slug", "")))
            slug = item.get("slug", job_id)
            org = item.get("organization") or item.get("company") or {}
            if not isinstance(org, dict):
                org = {}
            org_slug = org.get("slug", "")

            url = item.get("url") or f"{BASE_URL}/fr/companies/{org_slug}/jobs/{slug}"

            offices = item.get("offices") or []
            office = offices[0] if offices else {}
            if not isinstance(office, dict):
                office = {}
            city = office.get("city", item.get("city", ""))
            country = office.get("country", {})
            country_name = country.get("name", "") if isinstance(country, dict) else str(country)
            location = city
            if country_name and country_name not in ("France", "FR"):
                location = f"{city}, {country_name}"

            salary_min = item.get("salary_min") or item.get("salaryMin")
            salary_max = item.get("salary_max") or item.get("salaryMax")
            salary = None
            if salary_min and salary_max:
                salary = f"{salary_min}–{salary_max} €"
            elif salary_min:
                salary = f"À partir de {salary_min} €"

            title = item.get("name") or item.get("title", "")
            company_name = org.get("name") or item.get("companyName", "N/A")
            description = item.get("description") or item.get("body", "")
            contract = item.get("contract_type") or item.get("contractType", "")

            if not title:
                return None

            published = str(item.get("published_at") or item.get("publishedAt") or "")

            return JobOffer(
                id=f"wttj_{job_id}",
                title=title,
                company=company_name,
                location=location,
                description=description,
                url=url,
                apply_url=url,
                source=self.source_name,
                salary=salary,
                contract_type=contract,
                date_posted=published[:10] or None,
            )
        except Exception:
            return None
