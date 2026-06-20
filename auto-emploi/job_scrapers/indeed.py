import html as html_module
import json
import re
import time
import urllib.parse
import xml.etree.ElementTree as ET

# defusedxml neutralise les attaques XML (XXE, billion laughs) sur le flux RSS,
# qui est du contenu externe non fiable.
try:
    from defusedxml import ElementTree as SafeET
except ImportError:
    import warnings
    warnings.warn(
        "defusedxml non installé : le parsing RSS Indeed utilise la stdlib XML, "
        "vulnérable aux attaques XXE sur un flux RSS hostile. "
        "Installez defusedxml : pip install defusedxml",
        stacklevel=2,
    )
    SafeET = ET

from bs4 import BeautifulSoup

from .base import BaseScraper, JobOffer, MAX_RESPONSE_BYTES
from config import config

MAX_RSS_START = 500        # plafond pagination RSS (~50 pages de 10)
MAX_BROWSER_START = 300    # plafond pagination Playwright (~20 pages de 15)

HEADERS = {
    "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36",
    "Accept-Language": "fr-FR,fr;q=0.9",
    "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
    "Accept-Encoding": "gzip, deflate, br",
    "Connection": "keep-alive",
}

INDEED_NS = "https://www.indeed.com/about/rss"


def _domain() -> str:
    """Domaine Indeed du pays sélectionné (fr.indeed.com par défaut)."""
    from locations import INDEED_DOMAINS
    return INDEED_DOMAINS.get(config.country, "fr.indeed.com")


def _balanced_object(text: str, pos: int) -> str | None:
    """À partir de `pos`, renvoie le premier objet JSON `{...}` à accolades
    équilibrées (chaînes et échappements respectés), ou None. Linéaire, sans
    backtracking : robuste face à un JSON volumineux contenant des `}` internes
    suivis de `\\n` (cas que la regex non-gourmande tronquait)."""
    start = text.find("{", pos)
    if start == -1:
        return None
    depth, in_str, esc = 0, False, False
    for k in range(start, len(text)):
        ch = text[k]
        if in_str:
            if esc:
                esc = False
            elif ch == "\\":
                esc = True
            elif ch == '"':
                in_str = False
        elif ch == '"':
            in_str = True
        elif ch == "{":
            depth += 1
        elif ch == "}":
            depth -= 1
            if depth == 0:
                return text[start:k + 1]
    return None


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


class IndeedScraper(BaseScraper):
    source_name = "Indeed"

    def search(self, query: str, location: str = "", max_results: int = 50) -> list[JobOffer]:
        # Essai 1 : RSS (rapide, marche sur certains IPs)
        offers = self._search_rss(query, location, max_results)
        if offers:
            return offers

        # Essai 2 : Playwright → scraping page HTML (contourne Cloudflare)
        return self._search_playwright(query, location, max_results)

    # ─── Méthode RSS ──────────────────────────────────────────────────────────

    def _search_rss(self, query: str, location: str, max_results: int) -> list[JobOffer]:
        offers = []
        start = 0
        seen: set[str] = set()
        session = _make_session()
        if hasattr(session, "headers"):
            session.headers.update(HEADERS)

        while len(offers) < max_results and start <= MAX_RSS_START:
            params = {"q": query, "l": location, "sort": "date", "start": start}
            try:
                resp = session.get(f"https://{_domain()}/rss", params=params, timeout=15)
                if resp.status_code != 200 or len(resp.content) > MAX_RESPONSE_BYTES:
                    break
            except Exception:
                break

            try:
                root = SafeET.fromstring(resp.content)
            except Exception:
                break

            items = root.findall(".//item")
            if not items:
                break

            before = len(offers)
            for item in items:
                job = self._parse_rss_item(item)
                if job and job.unique_key() not in seen:
                    seen.add(job.unique_key())
                    offers.append(job)
                if len(offers) >= max_results:
                    break

            # Aucune offre nouvelle (page identique renvoyée) ou page partielle :
            # on arrête plutôt que de boucler sur des doublons.
            if len(offers) == before or len(items) < 10:
                break
            start += 10
            time.sleep(config.request_delay)

        return offers

    def _parse_rss_item(self, item: ET.Element) -> JobOffer | None:
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

            pub_date_raw = item.findtext("pubDate", "").strip()
            date_posted = None
            if pub_date_raw:
                try:
                    from email.utils import parsedate_to_datetime
                    date_posted = parsedate_to_datetime(pub_date_raw).strftime("%Y-%m-%d")
                except Exception:
                    pass

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
                date_posted=date_posted,
            )
        except Exception:
            return None

    # ─── Méthode Playwright ───────────────────────────────────────────────────

    def _search_playwright(self, query: str, location: str, max_results: int) -> list[JobOffer]:
        from ._browser import BrowserSession

        offers: list[JobOffer] = []
        seen: set[str] = set()

        with BrowserSession() as browser:
            if not browser.ready:
                return []

            start = 0
            while len(offers) < max_results and start <= MAX_BROWSER_START:
                params = {"q": query, "l": location, "sort": "date", "start": start}
                url = f"https://{_domain()}/jobs?" + urllib.parse.urlencode(params)

                html = browser.fetch(url, wait="domcontentloaded", extra_ms=2000)
                if html is None:
                    break

                before = len(offers)

                # Essai 1 : données JSON embarquées (mosaic)
                jobs_raw = self._extract_from_mosaic(html)
                if jobs_raw:
                    for item in jobs_raw:
                        job = self._parse_mosaic_item(item)
                        if job and job.unique_key() not in seen:
                            seen.add(job.unique_key())
                            offers.append(job)
                        if len(offers) >= max_results:
                            break
                    # Indeed sert parfois la même page quel que soit `start`
                    # (anti-scraping) : si aucune offre nouvelle, inutile
                    # d'insister sur les pages suivantes.
                    if len(offers) == before or len(jobs_raw) < 15:
                        break
                    start += len(jobs_raw)
                    time.sleep(config.request_delay)
                    continue

                # Essai 2 : parsing HTML des cartes
                cards = self._extract_from_html(html)
                if not cards:
                    break
                for job in cards:
                    if job.unique_key() not in seen:
                        seen.add(job.unique_key())
                        offers.append(job)
                    if len(offers) >= max_results:
                        break
                if len(offers) == before or len(cards) < 10:
                    break
                start += len(cards)
                time.sleep(config.request_delay)

        return offers

    def _extract_from_mosaic(self, html: str) -> list[dict]:
        """Extrait les données JSON du bundle mosaic embarqué par Indeed.
        Extraction par accolades équilibrées (et non regex non-gourmande) : le
        JSON est volumineux et un `}` interne suivi d'un saut de ligne tronquait
        l'ancienne capture, faisant échouer le parsing le plus riche."""
        anchor = re.search(
            r'window\.mosaic\.providerData\["mosaic-provider-jobcards"\]\s*=\s*',
            html,
        )
        if not anchor:
            return []
        blob = _balanced_object(html, anchor.end())
        if blob is None:
            return []
        try:
            data = json.loads(blob)
            return (
                data.get("metaData", {})
                .get("mosaicProviderJobCardsModel", {})
                .get("results", [])
            )
        except Exception:
            return []

    def _parse_mosaic_item(self, item: dict) -> JobOffer | None:
        try:
            job_key = item.get("jobkey", "")
            title = (item.get("displayTitle") or item.get("title") or "").strip()
            if not title or not job_key:
                return None

            company = item.get("company", "N/A")
            location = item.get("formattedLocation") or item.get("jobLocationCity", "")
            description = re.sub(r"<[^>]+>", " ", item.get("snippet") or "").strip()
            url = f"https://{_domain()}/viewjob?jk={job_key}"

            sal = item.get("salarySnippet") or {}
            salary = sal.get("text") if isinstance(sal, dict) else None

            return JobOffer(
                id=f"indeed_{job_key}",
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

    def _extract_from_html(self, html: str) -> list[JobOffer]:
        """Fallback : parsing HTML des cartes avec BeautifulSoup."""
        soup = BeautifulSoup(html, "html.parser")
        cards = soup.find_all("div", attrs={"data-jk": True})
        offers = []
        for card in cards:
            try:
                job_key = card.get("data-jk", "")
                title_el = card.find(["h2", "span"], class_=re.compile(r"jobTitle"))
                title = title_el.get_text(strip=True) if title_el else ""
                if not title:
                    continue

                company_el = card.find(attrs={"data-testid": "company-name"}) or card.find(class_=re.compile(r"companyName"))
                company = company_el.get_text(strip=True) if company_el else "N/A"

                loc_el = card.find(attrs={"data-testid": "text-location"}) or card.find(class_=re.compile(r"companyLocation"))
                location = loc_el.get_text(strip=True) if loc_el else ""

                url = f"https://{_domain()}/viewjob?jk={job_key}" if job_key else ""
                if not url:
                    continue

                offers.append(JobOffer(
                    id=f"indeed_{job_key}",
                    title=title,
                    company=company,
                    location=location,
                    description="",
                    url=url,
                    apply_url=url,
                    source=self.source_name,
                ))
            except Exception:
                continue
        return offers
