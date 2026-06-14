"""
Scraper LinkedIn.

Deux modes :
- INVITÉ (défaut, sans identifiants) : API publique "jobs-guest" de LinkedIn,
  celle qui alimente les pages visibles sans connexion. Aucun compte requis,
  aucun compte ne peut être bloqué.
- CONNECTÉ (si LINKEDIN_EMAIL/PASSWORD configurés) : via Playwright.
  AVERTISSEMENT : contraire aux CGU LinkedIn — à vos risques, votre compte
  peut être restreint.
"""
import re
import time
import urllib.parse

from .base import BaseScraper, JobOffer, MAX_RESPONSE_BYTES
from config import config

GUEST_API = "https://www.linkedin.com/jobs-guest/jobs/api/seeMoreJobPostings/search"
MAX_GUEST_START = 200  # plafond pagination mode invité

_HEADERS = {
    "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36",
    "Accept-Language": "fr-FR,fr;q=0.9",
}


class LinkedInScraper(BaseScraper):
    source_name = "LinkedIn"

    def search(self, query: str, location: str = "", max_results: int = 50) -> list[JobOffer]:
        if config.linkedin_email and config.linkedin_password:
            return self._search_logged_in(query, location, max_results)
        return self._search_guest(query, location, max_results)

    # ─── Mode invité (sans login) ────────────────────────────────────────────

    def _search_guest(self, query: str, location: str, max_results: int) -> list[JobOffer]:
        import requests
        from bs4 import BeautifulSoup

        offers: list[JobOffer] = []
        seen: set[str] = set()
        session = requests.Session()
        session.headers.update(_HEADERS)
        start = 0

        while len(offers) < max_results and start <= MAX_GUEST_START:
            from locations import COUNTRY_NAMES
            params = {
                "keywords": query,
                "location": location or COUNTRY_NAMES.get(config.country, "France"),
                "start": start,
                "f_TPR": "r604800",  # offres de moins de 7 jours
            }
            try:
                resp = session.get(GUEST_API, params=params, timeout=15)
                if resp.status_code != 200 or len(resp.content) > MAX_RESPONSE_BYTES:
                    break
            except Exception:
                break

            soup = BeautifulSoup(resp.text, "html.parser")
            cards = soup.find_all("li")
            if not cards:
                break

            added = 0
            for card in cards:
                job = self._parse_guest_card(card)
                if job and job.unique_key() not in seen:
                    seen.add(job.unique_key())
                    offers.append(job)
                    added += 1
                if len(offers) >= max_results:
                    break

            if added == 0:
                break
            start += 25
            time.sleep(config.request_delay)

        return offers

    def _parse_guest_card(self, card) -> JobOffer | None:
        try:
            title_el = card.select_one(".base-search-card__title")
            company_el = card.select_one(".base-search-card__subtitle")
            location_el = card.select_one(".job-search-card__location")
            link_el = card.select_one("a.base-card__full-link") or card.select_one("a[href*='/jobs/view/']")

            if not title_el or not link_el:
                return None

            title = title_el.get_text(strip=True)
            company = company_el.get_text(strip=True) if company_el else "N/A"
            location = location_el.get_text(strip=True) if location_el else ""
            url = (link_el.get("href") or "").split("?")[0]

            m = re.search(r"/jobs/view/[^/]*?(\d+)", url)
            unique_id = m.group(1) if m else re.sub(r"[^a-z0-9]", "", f"{title}{company}".lower())[:60]

            return JobOffer(
                id=f"linkedin_{unique_id}",
                title=title,
                company=company,
                location=location,
                description="",
                url=url,
                apply_url=url,
                source=self.source_name,
            )
        except Exception:
            return None

    # ─── Mode connecté (Playwright) ──────────────────────────────────────────

    def _search_logged_in(self, query: str, location: str, max_results: int) -> list[JobOffer]:
        try:
            from playwright.sync_api import sync_playwright
        except ImportError:
            raise ImportError("Playwright requis : pip install playwright && python -m playwright install chromium")

        from ._browser import _launch_args

        offers = []
        with sync_playwright() as p:
            browser = p.chromium.launch(headless=True, args=_launch_args())
            context = browser.new_context(
                user_agent=_HEADERS["User-Agent"],
                locale="fr-FR",
                accept_downloads=False,
            )
            page = context.new_page()
            self._login(page)
            offers = self._scrape_jobs(page, query, location, max_results)
            browser.close()

        return offers

    def _login(self, page) -> None:
        page.goto("https://www.linkedin.com/login", wait_until="domcontentloaded")

        # LinkedIn peut afficher : formulaire complet, mot de passe seul (session partielle)
        # ou rien (déjà connecté — redirigé vers /feed ou /jobs).
        # On détecte l'état réel plutôt que d'attendre un sélecteur absent.
        _T = 4000  # timeout court pour les vérifications de présence

        has_username = page.locator("#username").count() > 0
        if has_username:
            page.fill("#username", config.linkedin_email)

        has_password = page.locator("#password").count() > 0
        if has_password:
            page.fill("#password", config.linkedin_password)

        if not has_username and not has_password:
            # Déjà connecté : LinkedIn a redirigé avant même d'afficher le login.
            return

        # Soumettre uniquement si un champ était présent
        try:
            page.click("button[type='submit']", timeout=_T)
        except Exception:
            pass

        try:
            page.wait_for_url("**/feed/**", timeout=10000)
        except Exception:
            # Captcha, 2FA ou redirect inattendu — on continue prudemment
            page.wait_for_timeout(3000)

    def _scrape_jobs(self, page, query: str, location: str, max_results: int) -> list[JobOffer]:
        offers = []
        start = 0
        seen = set()

        while len(offers) < max_results and start <= MAX_GUEST_START:
            url = (
                f"https://www.linkedin.com/jobs/search/"
                f"?keywords={urllib.parse.quote_plus(query)}&location={urllib.parse.quote_plus(location)}"
                f"&start={start}&f_TPR=r604800"
            )
            page.goto(url, wait_until="domcontentloaded")
            page.wait_for_timeout(2000)

            cards = page.query_selector_all(".job-search-card, .base-card")
            if not cards:
                break

            for card in cards:
                job = self._parse_card(card)
                if job and job.unique_key() not in seen:
                    seen.add(job.unique_key())
                    offers.append(job)
                if len(offers) >= max_results:
                    break

            if len(cards) < 25:
                break
            start += 25
            time.sleep(config.request_delay)

        return offers

    def _parse_card(self, card) -> JobOffer | None:
        try:
            title_el = card.query_selector(".base-search-card__title, h3.job-search-card__title")
            company_el = card.query_selector(".base-search-card__subtitle, h4.job-search-card__company-name")
            location_el = card.query_selector(".job-search-card__location")
            link_el = card.query_selector("a.base-card__full-link, a.job-search-card__list-date")

            if not title_el or not link_el:
                return None

            title = title_el.inner_text().strip()
            company = company_el.inner_text().strip() if company_el else "N/A"
            location = location_el.inner_text().strip() if location_el else ""
            url = link_el.get_attribute("href") or ""
            if "?" in url:
                url = url.split("?")[0]

            job_id = re.search(r"/jobs/view/(\d+)", url)
            unique_id = job_id.group(1) if job_id else re.sub(r"[^a-z0-9]", "", f"{title}{company}".lower())

            return JobOffer(
                id=f"linkedin_{unique_id}",
                title=title,
                company=company,
                location=location,
                description="",
                url=url,
                apply_url=url,
                source=self.source_name,
            )
        except Exception:
            return None
