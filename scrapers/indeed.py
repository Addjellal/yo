import html as html_module
import re
import time
import xml.etree.ElementTree as ET

from .base import BaseScraper, JobOffer
from config import config
from utils import console

HEADERS = {
    "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36",
    "Accept-Language": "fr-FR,fr;q=0.9",
    "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
    "Accept-Encoding": "gzip, deflate, br",
    "Connection": "keep-alive",
}

INDEED_NS = "https://www.indeed.com/about/rss"
RSS_URL = "https://fr.indeed.com/rss"


def _make_session():
    """Crée une session qui contourne Cloudflare/anti-bot si cloudscraper est disponible."""
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


class IndeedScraper(BaseScraper):
    source_name = "Indeed"

    def search(self, query: str, location: str = "", max_results: int = 50) -> list[JobOffer]:
        """Scrape Indeed via leur flux RSS."""
        offers = []
        start = 0
        seen: set[str] = set()
        session = _make_session()
        if hasattr(session, "headers"):
            session.headers.update(HEADERS)

        while len(offers) < max_results:
            params = {"q": query, "l": location, "sort": "date", "start": start}
            try:
                resp = session.get(RSS_URL, params=params, timeout=15)
                if resp.status_code == 403:
                    console.print(
                        "[yellow][Indeed] Bloqué (403). "
                        "Installez cloudscraper : pip install cloudscraper[/yellow]"
                    )
                    break
                resp.raise_for_status()
            except Exception as e:
                if "403" not in str(e):
                    console.print(f"[yellow][Indeed] Erreur réseau : {e}[/yellow]")
                break

            try:
                root = ET.fromstring(resp.content)
            except ET.ParseError as e:
                console.print(f"[yellow][Indeed] Erreur parsing RSS : {e}[/yellow]")
                break

            items = root.findall(".//item")
            if not items:
                break

            for item in items:
                job = self._parse_item(item)
                if job and job.unique_key() not in seen:
                    seen.add(job.unique_key())
                    offers.append(job)
                if len(offers) >= max_results:
                    break

            if len(items) < 10:
                break
            start += 10
            time.sleep(config.request_delay)

        return offers

    def _parse_item(self, item: ET.Element) -> JobOffer | None:
        try:
            ns = INDEED_NS
            raw_title = item.findtext("title", "").strip()

            if " - " in raw_title:
                title, company = raw_title.rsplit(" - ", 1)
                title = title.strip()
                company = company.strip()
            else:
                title = raw_title
                company = item.findtext(f"{{{ns}}}source", "N/A").strip()

            link = item.findtext("link", "").strip()
            raw_desc = item.findtext("description", "")
            description = re.sub(r"<[^>]+>", " ", html_module.unescape(raw_desc)).strip()
            description = re.sub(r"\s+", " ", description)

            city = item.findtext(f"{{{ns}}}city", "").strip()
            state = item.findtext(f"{{{ns}}}state", "").strip()
            location = ", ".join(filter(None, [city, state]))

            jobkey = item.findtext(f"{{{ns}}}jobkey", "").strip()
            salary = item.findtext(f"{{{ns}}}salary", "").strip() or None

            if not title or not link:
                return None

            uid = jobkey or re.sub(r"[^a-z0-9]", "", f"{title}{company}".lower())
            return JobOffer(
                id=f"indeed_{uid}",
                title=title,
                company=company,
                location=location,
                description=description,
                url=link,
                apply_url=link,
                source=self.source_name,
                salary=salary,
            )
        except Exception:
            return None
