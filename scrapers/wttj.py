import json
import time
import urllib.parse

import requests
from bs4 import BeautifulSoup

from .base import BaseScraper, JobOffer
from config import config
from utils import console

BASE_URL = "https://www.welcometothejungle.com"
HEADERS = {
    "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36",
    "Accept-Language": "fr-FR,fr;q=0.9",
    "Accept": "text/html,application/xhtml+xml,*/*",
}


class WTTJScraper(BaseScraper):
    source_name = "Welcome to the Jungle"

    def search(self, query: str, location: str = "", max_results: int = 50) -> list[JobOffer]:
        """Scrape WTTJ via __NEXT_DATA__ JSON embedded in their HTML pages."""
        offers = []
        page = 1
        session = requests.Session()
        session.headers.update(HEADERS)

        while len(offers) < max_results:
            params: dict = {"query": query, "page": page}
            if location:
                params["aroundQuery"] = location

            url = f"{BASE_URL}/fr/jobs?" + urllib.parse.urlencode(params)
            try:
                resp = session.get(url, timeout=15)
                resp.raise_for_status()
            except requests.RequestException as e:
                console.print(f"[yellow][WTTJ] Erreur réseau : {e}[/yellow]")
                break

            jobs_page = self._extract_from_next_data(resp.text)
            if not jobs_page:
                break

            for item in jobs_page:
                job = self._parse_item(item)
                if job:
                    offers.append(job)
                if len(offers) >= max_results:
                    break

            if len(jobs_page) < 15:
                break
            page += 1
            time.sleep(config.request_delay)

        return offers

    def _extract_from_next_data(self, html: str) -> list[dict]:
        """Extract job list from Next.js __NEXT_DATA__ script tag."""
        try:
            soup = BeautifulSoup(html, "html.parser")
            script = soup.find("script", id="__NEXT_DATA__")
            if not script or not script.string:
                return []
            data = json.loads(script.string)
            # Navigate the Next.js data tree
            props = data.get("props", {}).get("pageProps", {})
            # Try several known key paths
            for key in ("jobs", "jobOffers", "results"):
                if key in props:
                    return props[key]
            # Fallback: look inside nested 'data'
            for key in ("jobs", "jobOffers", "results"):
                val = props.get("data", {}).get(key)
                if val:
                    return val
            return []
        except (json.JSONDecodeError, AttributeError):
            return []

    def _parse_item(self, item: dict) -> JobOffer | None:
        try:
            job_id = str(item.get("id", item.get("slug", "")))
            slug = item.get("slug", job_id)
            org = item.get("organization", item.get("company", {}))
            org_slug = org.get("slug", "")

            url = (
                item.get("url")
                or f"{BASE_URL}/fr/companies/{org_slug}/jobs/{slug}"
            )

            offices = item.get("offices", [])
            office = offices[0] if offices else {}
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
            )
        except Exception:
            return None
