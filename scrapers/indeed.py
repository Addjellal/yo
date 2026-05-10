import time
import re
import requests
from bs4 import BeautifulSoup
from .base import BaseScraper, JobOffer
from config import config

HEADERS = {
    "User-Agent": (
        "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 "
        "(KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36"
    ),
    "Accept-Language": "fr-FR,fr;q=0.9,en;q=0.8",
    "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
}


class IndeedScraper(BaseScraper):
    source_name = "Indeed"

    def search(self, query: str, location: str = "", max_results: int = 50) -> list[JobOffer]:
        offers = []
        start = 0
        seen = set()
        session = requests.Session()
        session.headers.update(HEADERS)

        while len(offers) < max_results:
            params = {"q": query, "l": location, "start": start, "lang": "fr"}
            try:
                resp = session.get("https://fr.indeed.com/emplois", params=params, timeout=15)
                resp.raise_for_status()
            except requests.RequestException as e:
                print(f"[Indeed] Erreur réseau : {e}")
                break

            soup = BeautifulSoup(resp.text, "html.parser")
            cards = soup.select("div.job_seen_beacon, li.css-1ac2h1w")

            if not cards:
                break

            for card in cards:
                job = self._parse_card(card)
                if job and job.unique_key() not in seen:
                    seen.add(job.unique_key())
                    offers.append(job)
                if len(offers) >= max_results:
                    break

            start += 10
            time.sleep(config.request_delay)

        return offers

    def _parse_card(self, card) -> JobOffer | None:
        try:
            title_el = card.select_one("h2.jobTitle a, a.jcs-JobTitle")
            if not title_el:
                return None
            title = title_el.get_text(strip=True)
            job_id = title_el.get("id", "") or title_el.get("data-jk", "")
            href = title_el.get("href", "")
            url = f"https://fr.indeed.com{href}" if href.startswith("/") else href

            company = (card.select_one("[data-testid='company-name'], .companyName") or {}).get_text(strip=True) if card.select_one("[data-testid='company-name'], .companyName") else "N/A"
            location = (card.select_one("[data-testid='text-location'], .companyLocation") or {}).get_text(strip=True) if card.select_one("[data-testid='text-location'], .companyLocation") else ""
            salary_el = card.select_one("[data-testid='attribute_snippet_testid'], .salary-snippet-container")
            salary = salary_el.get_text(strip=True) if salary_el else None
            desc_el = card.select_one(".job-snippet, [data-testid='jobsnippet_footer']")
            description = desc_el.get_text(" ", strip=True) if desc_el else ""

            unique_id = re.sub(r"[^a-z0-9]", "", job_id.lower()) or re.sub(r"[^a-z0-9]", "", f"{title}{company}".lower())

            return JobOffer(
                id=f"indeed_{unique_id}",
                title=title,
                company=company,
                location=location,
                description=description,
                url=url,
                apply_url=url,
                source=self.source_name,
                salary=salary,
            )
        except Exception:
            return None
