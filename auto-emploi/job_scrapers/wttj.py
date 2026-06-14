import json
import time
import urllib.parse

from bs4 import BeautifulSoup

from .base import BaseScraper, JobOffer, MAX_RESPONSE_BYTES
from config import config

MAX_PAGES = 20
BASE_URL = "https://www.welcometothejungle.com"
HEADERS = {
    "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36",
    "Accept-Language": "fr-FR,fr;q=0.9",
    "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,*/*;q=0.8",
    "Accept-Encoding": "gzip, deflate, br",
    "Connection": "keep-alive",
    "Upgrade-Insecure-Requests": "1",
    "Cache-Control": "max-age=0",
}


def _make_session():
    try:
        import cloudscraper
        return cloudscraper.create_scraper(
            browser={"browser": "chrome", "platform": "windows", "mobile": False}
        )
    except ImportError:
        import requests as _r
        s = _r.Session()
        s.headers.update(HEADERS)
        return s


class WTTJScraper(BaseScraper):
    source_name = "Welcome to the Jungle"

    def search(self, query: str, location: str = "", max_results: int = 50) -> list[JobOffer]:
        offers = []
        page = 1
        session = _make_session()
        if hasattr(session, "headers"):
            session.headers.update(HEADERS)

        # Playwright session, initialisée paresseusement si cloudscraper bloque
        from ._browser import BrowserSession
        browser = BrowserSession()
        browser_tried = False

        try:
            while len(offers) < max_results and page <= MAX_PAGES:
                params: dict = {"query": query, "page": page}
                if location:
                    params["aroundQuery"] = location
                url = f"{BASE_URL}/fr/jobs?" + urllib.parse.urlencode(params)

                html = None
                # 1. Essai rapide via requests/cloudscraper
                try:
                    resp = session.get(url, timeout=20)
                    if resp.status_code == 200 and len(resp.content) <= MAX_RESPONSE_BYTES:
                        html = resp.text
                except Exception:
                    pass

                # 2. Fallback Playwright si bloqué
                if html is None:
                    if not browser_tried:
                        browser_tried = True
                        browser.start()
                    if browser.ready:
                        html = browser.fetch(url, wait="networkidle", extra_ms=1000)

                if html is None:
                    break

                jobs_page = self._extract_from_next_data(html)
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

        finally:
            browser.close()

        return offers

    def _extract_from_next_data(self, html: str) -> list[dict]:
        try:
            soup = BeautifulSoup(html, "html.parser")
            script = soup.find("script", id="__NEXT_DATA__")
            if not script or not script.string:
                return []
            data = json.loads(script.string)
            props = data.get("props", {}).get("pageProps", {})
            for key in ("jobs", "jobOffers", "results", "hits"):
                if key in props:
                    return props[key]
            for key in ("jobs", "jobOffers", "results", "hits"):
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
