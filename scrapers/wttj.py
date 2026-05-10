import time
import requests
from .base import BaseScraper, JobOffer
from config import config

SEARCH_URL = "https://api.welcometothejungle.com/api/v1/jobs"
HEADERS = {
    "User-Agent": "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 Chrome/124.0.0.0 Safari/537.36",
    "Accept": "application/json",
    "Accept-Language": "fr-FR,fr;q=0.9",
    "Referer": "https://www.welcometothejungle.com/",
    "Origin": "https://www.welcometothejungle.com",
}


class WTTJScraper(BaseScraper):
    source_name = "Welcome to the Jungle"

    def search(self, query: str, location: str = "", max_results: int = 50) -> list[JobOffer]:
        offers = []
        page = 1
        session = requests.Session()
        session.headers.update(HEADERS)

        while len(offers) < max_results:
            params = {
                "query": query,
                "page": page,
                "per_page": min(30, max_results - len(offers)),
            }
            if location:
                params["location_geoname_id"] = location

            try:
                resp = session.get(SEARCH_URL, params=params, timeout=15)
                if resp.status_code == 404:
                    break
                resp.raise_for_status()
                data = resp.json()
            except Exception as e:
                print(f"[WTTJ] Erreur : {e}")
                break

            jobs = data.get("jobs", data.get("results", []))
            if not jobs:
                break

            for item in jobs:
                job = self._parse_item(item)
                if job:
                    offers.append(job)
                if len(offers) >= max_results:
                    break

            if len(jobs) < 30:
                break
            page += 1
            time.sleep(config.request_delay)

        return offers

    def _parse_item(self, item: dict) -> JobOffer | None:
        try:
            job_id = str(item.get("id", item.get("slug", "")))
            slug = item.get("slug", job_id)
            org = item.get("organization", {})
            org_slug = org.get("slug", "")
            url = f"https://www.welcometothejungle.com/fr/companies/{org_slug}/jobs/{slug}"

            office = item.get("offices", [{}])[0] if item.get("offices") else {}
            location = office.get("city", item.get("city", ""))
            if office.get("country"):
                location = f"{location}, {office['country']}"

            salary_min = item.get("salary_min")
            salary_max = item.get("salary_max")
            salary = None
            if salary_min and salary_max:
                salary = f"{salary_min}–{salary_max} €"
            elif salary_min:
                salary = f"À partir de {salary_min} €"

            return JobOffer(
                id=f"wttj_{job_id}",
                title=item.get("name", ""),
                company=org.get("name", "N/A"),
                location=location,
                description=item.get("description", ""),
                url=url,
                apply_url=url,
                source=self.source_name,
                salary=salary,
                contract_type=item.get("contract_type"),
            )
        except Exception:
            return None
