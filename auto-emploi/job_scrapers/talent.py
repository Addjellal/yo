"""
Scraper Talent.com — agrégateur d'offres multi-pays (sous-domaine par pays).

Talent.com rend ses résultats côté serveur en HTML : on lit d'abord les blocs
JSON-LD (`JobPosting`) quand ils sont présents — données structurées propres —
puis on retombe sur le parsing des cartes HTML avec BeautifulSoup. Les sélecteurs
sont volontairement tolérants (plusieurs variantes de classes) car la mise en
page évolue ; en cas de blocage anti-bot, on tente Playwright comme les autres
scrapers.

Aucune authentification requise.
"""
import json
import time
import urllib.parse

from bs4 import BeautifulSoup

from .base import BaseScraper, JobOffer, MAX_RESPONSE_BYTES
from config import config
from app_utils import console

MAX_PAGES = 20
PAGE_SIZE_HINT = 10  # talent.com sert ~10 offres/page

HEADERS = {
    "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36",
    "Accept-Language": "fr-FR,fr;q=0.9",
    "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
    "Accept-Encoding": "gzip, deflate, br",
    "Connection": "keep-alive",
}


def _domain() -> str:
    """Sous-domaine Talent.com du pays sélectionné (fr.talent.com par défaut)."""
    from locations import TALENT_DOMAINS
    return TALENT_DOMAINS.get(config.country, "fr.talent.com")


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


class TalentScraper(BaseScraper):
    source_name = "Talent.com"

    def search(self, query: str, location: str = "", max_results: int = 50) -> list[JobOffer]:
        offers: list[JobOffer] = []
        seen: set[str] = set()
        base = f"https://{_domain()}"
        session = _make_session()

        # Playwright initialisé paresseusement si requests/cloudscraper est bloqué.
        from ._browser import BrowserSession
        browser = BrowserSession()
        browser_tried = False

        try:
            page = 1
            while len(offers) < max_results and page <= MAX_PAGES:
                params = {"k": query, "l": location, "p": page}
                url = f"{base}/jobs?" + urllib.parse.urlencode(params)

                html = None
                try:
                    resp = session.get(url, timeout=20)
                    if resp.status_code == 200 and len(resp.content) <= MAX_RESPONSE_BYTES:
                        html = resp.text
                    elif page == 1:
                        console.print(
                            f"[yellow]Talent.com : HTTP {resp.status_code} en direct "
                            f"(blocage anti-bot probable) — tentative navigateur…[/yellow]"
                        )
                except Exception as e:
                    if page == 1:
                        console.print(f"[dim]Talent.com : requête directe échouée ({e}) — navigateur…[/dim]")

                if html is None:  # repli navigateur (anti-bot)
                    if not browser_tried:
                        browser_tried = True
                        browser.start()
                        if not browser.ready and page == 1:
                            console.print(
                                "[yellow]Talent.com : Playwright indisponible "
                                "(navigateur non installé ?) — source ignorée.[/yellow]"
                            )
                    if browser.ready:
                        html = browser.fetch(url, wait="domcontentloaded", extra_ms=1500)

                if html is None:
                    break

                page_jobs = self._parse_page(html, base)
                if not page_jobs:
                    if page == 1:
                        console.print(
                            "[yellow]Talent.com : page reçue mais 0 offre extraite "
                            "(sélecteurs HTML à mettre à jour).[/yellow]"
                        )
                    break

                before = len(offers)
                for job in page_jobs:
                    if job.unique_key() not in seen:
                        seen.add(job.unique_key())
                        offers.append(job)
                    if len(offers) >= max_results:
                        break

                # Page sans nouveauté (même contenu resservi) ou partielle : on arrête.
                if len(offers) == before or len(page_jobs) < PAGE_SIZE_HINT:
                    break
                page += 1
                time.sleep(config.request_delay)
        finally:
            browser.close()

        return offers

    # ─── Parsing ────────────────────────────────────────────────────────────

    def _parse_page(self, html: str, base: str) -> list[JobOffer]:
        """Les offres vivent dans le payload RSC Next.js (self.__next_f) : c'est
        la source principale. JSON-LD (souvent juste des liens) et cartes HTML
        (une seule rendue côté serveur) ne servent que de repli."""
        jobs = self._parse_next_f(html, base)
        if jobs:
            return jobs
        soup = BeautifulSoup(html, "html.parser")
        jobs = self._parse_jsonld(soup, base)
        if jobs:
            return jobs
        return self._parse_cards(soup, base)

    # ─── Payload RSC (self.__next_f) ─────────────────────────────────────────

    def _parse_next_f(self, html: str, base: str) -> list[JobOffer]:
        """Reconstitue le flux RSC (suite de self.__next_f.push([1,"…"])) puis en
        extrait le tableau "jobs":[…] sérialisé par Next.js."""
        import re
        chunks = re.findall(
            r'self\.__next_f\.push\(\[1,\s*("(?:[^"\\]|\\.)*")\]\)', html, re.S
        )
        if not chunks:
            return []
        parts: list[str] = []
        for c in chunks:
            try:
                parts.append(json.loads(c))
            except (json.JSONDecodeError, ValueError):
                pass
        payload = "".join(parts)
        offers: list[JobOffer] = []
        for job in self._extract_jobs_array(payload):
            off = self._parse_next_f_job(job, base)
            if off:
                offers.append(off)
        return offers

    @staticmethod
    def _extract_jobs_array(payload: str) -> list[dict]:
        """Extrait le tableau "jobs":[…] (parenthésage équilibré, en ignorant
        crochets et guillemets situés à l'intérieur des chaînes)."""
        key = '"jobs":'
        pos = payload.find(key)
        while pos != -1:
            start = payload.find("[", pos)
            if start == -1:
                break
            depth, in_str, esc = 0, False, False
            for k in range(start, len(payload)):
                ch = payload[k]
                if in_str:
                    if esc:
                        esc = False
                    elif ch == "\\":
                        esc = True
                    elif ch == '"':
                        in_str = False
                elif ch == '"':
                    in_str = True
                elif ch == "[":
                    depth += 1
                elif ch == "]":
                    depth -= 1
                    if depth == 0:
                        try:
                            arr = json.loads(payload[start:k + 1])
                            if (isinstance(arr, list) and arr
                                    and isinstance(arr[0], dict)
                                    and ("source_title" in arr[0]
                                         or "distilled_title" in arr[0])):
                                return arr
                        except (json.JSONDecodeError, ValueError):
                            pass
                        break
            pos = payload.find(key, pos + 1)
        return []

    def _parse_next_f_job(self, j: dict, base: str) -> JobOffer | None:
        try:
            title = str(j.get("source_title") or j.get("distilled_title") or "").strip()
            if not title:
                return None
            job_id = str(j.get("id") or "").strip()
            company = str(j.get("enrich_company_name") or "").strip() or "N/A"
            location = str(j.get("source_location")
                           or j.get("enrich_geo_city") or "").strip()
            description = str(j.get("source_jobdesc_text") or "").strip()
            view_url = f"{base}/view?id={job_id}" if job_id else ""
            apply_url = str(j.get("source_link") or "").strip() or view_url
            url = view_url or apply_url

            salary = None
            if j.get("show_salary_on_front"):
                mn = j.get("enrich_salary_min") or 0
                mx = j.get("enrich_salary_max") or 0
                cur = j.get("enrich_salary_currency") or "€"
                if mn and mx:
                    salary = f"{mn}–{mx} {cur}"
                elif mn or mx:
                    salary = f"{mn or mx} {cur}"

            uid = job_id or f"{title}|{company}"
            return JobOffer(
                id=f"talent_{job_id or abs(hash(uid)) % 10**12}",
                title=title, company=company, location=location,
                description=description, url=url, apply_url=apply_url,
                source=self.source_name, salary=salary,
            )
        except Exception:
            return None

    def _parse_jsonld(self, soup: BeautifulSoup, base: str) -> list[JobOffer]:
        """Blocs <script type="application/ld+json"> de type JobPosting."""
        offers: list[JobOffer] = []
        for script in soup.find_all("script", attrs={"type": "application/ld+json"}):
            if not script.string:
                continue
            try:
                data = json.loads(script.string)
            except (json.JSONDecodeError, ValueError):
                continue
            for node in self._iter_jobpostings(data):
                job = self._parse_jsonld_item(node, base)
                if job:
                    offers.append(job)
        return offers

    @staticmethod
    def _iter_jobpostings(data) -> list[dict]:
        """Aplati les JobPosting d'un JSON-LD (objet seul, @graph, ItemList)."""
        out: list[dict] = []

        def _walk(node):
            if isinstance(node, list):
                for n in node:
                    _walk(n)
            elif isinstance(node, dict):
                t = node.get("@type")
                types = t if isinstance(t, list) else [t]
                if "JobPosting" in types:
                    out.append(node)
                # Conteneurs courants : @graph, itemListElement[*].item
                for key in ("@graph", "itemListElement"):
                    if key in node:
                        _walk(node[key])
                if "item" in node and isinstance(node["item"], (dict, list)):
                    _walk(node["item"])
        _walk(data)
        return out

    def _parse_jsonld_item(self, item: dict, base: str) -> JobOffer | None:
        try:
            title = str(item.get("title") or "").strip()
            if not title:
                return None
            org = item.get("hiringOrganization") or {}
            company = (org.get("name") if isinstance(org, dict) else str(org)) or "N/A"

            loc = self._jsonld_location(item.get("jobLocation"))
            url = str(item.get("url") or "")
            if url and url.startswith("/"):
                url = base + url
            description = str(item.get("description") or "")
            contract = str(item.get("employmentType") or "") or None
            salary = self._jsonld_salary(item.get("baseSalary"))
            posted = str(item.get("datePosted") or "")[:10] or None

            uid = url or f"{title}|{company}"
            return JobOffer(
                id=f"talent_{abs(hash(uid)) % 10**12}",
                title=title, company=str(company).strip(), location=loc,
                description=description, url=url, apply_url=url,
                source=self.source_name, salary=salary,
                contract_type=contract, date_posted=posted,
            )
        except Exception:
            return None

    @staticmethod
    def _jsonld_location(node) -> str:
        if isinstance(node, list):
            node = node[0] if node else None
        if isinstance(node, dict):
            addr = node.get("address")
            if isinstance(addr, dict):
                parts = [addr.get("addressLocality"), addr.get("addressRegion")]
                return ", ".join(p for p in parts if p)
            if isinstance(addr, str):
                return addr
            return str(node.get("name") or "")
        return str(node or "")

    @staticmethod
    def _jsonld_salary(node) -> str | None:
        if not isinstance(node, dict):
            return None
        value = node.get("value")
        if isinstance(value, dict):
            mn, mx = value.get("minValue"), value.get("maxValue")
            cur = node.get("currency") or "€"
            if mn and mx:
                return f"{mn}–{mx} {cur}"
            if mn or mx:
                return f"{mn or mx} {cur}"
        return None

    def _parse_cards(self, soup: BeautifulSoup, base: str) -> list[JobOffer]:
        """Repli : cartes HTML. Sélecteurs tolérants (la mise en page change)."""
        import re
        offers: list[JobOffer] = []
        seen: set[str] = set()
        # Cartes candidates : conteneurs portant une classe « card » avec un titre.
        cards = soup.find_all(class_=re.compile(r"JobCard_card__|\bcard\b"))
        for card in cards:
            try:
                title_el = card.find(class_=re.compile(r"JobCard_title__|job-?title", re.I)) \
                    or card.find(["h2", "h3"])
                title = title_el.get_text(strip=True) if title_el else ""
                if not title:
                    continue
                comp_el = card.find(class_=re.compile(r"empname|employer|company", re.I))
                company = comp_el.get_text(strip=True) if comp_el else "N/A"
                loc_el = card.find(class_=re.compile(r"location", re.I))
                location = loc_el.get_text(strip=True) if loc_el else ""
                snip_el = card.find(class_=re.compile(r"snippet|description", re.I))
                description = snip_el.get_text(" ", strip=True) if snip_el else ""

                href = ""
                anchor = card if card.name == "a" else card.find("a", href=True)
                if anchor and anchor.get("href"):
                    href = anchor["href"]
                elif card.get("data-url"):
                    href = card["data-url"]
                if href.startswith("/"):
                    href = base + href

                key = f"{title.lower()}|{company.lower()}"
                if key in seen:
                    continue
                seen.add(key)
                offers.append(JobOffer(
                    id=f"talent_{abs(hash(href or key)) % 10**12}",
                    title=title, company=company, location=location,
                    description=description, url=href, apply_url=href,
                    source=self.source_name,
                ))
            except Exception:
                continue
        return offers
