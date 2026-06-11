"""
Scraper LinkedIn via Playwright.
AVERTISSEMENT : Le scraping LinkedIn est contraire à leurs CGU.
Utilisez ce module uniquement à des fins personnelles et à vos risques.
LinkedIn peut bloquer votre compte en cas d'utilisation abusive.
"""
import time
import re
from .base import BaseScraper, JobOffer
from config import config


class LinkedInScraper(BaseScraper):
    source_name = "LinkedIn"

    def search(self, query: str, location: str = "", max_results: int = 50) -> list[JobOffer]:
        try:
            from playwright.sync_api import sync_playwright
        except ImportError:
            raise ImportError("Playwright requis : pip install playwright && playwright install chromium")

        from ._browser import _launch_args

        offers = []
        with sync_playwright() as p:
            browser = p.chromium.launch(headless=True, args=_launch_args())
            context = browser.new_context(
                user_agent="Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 Chrome/124.0.0.0 Safari/537.36",
                locale="fr-FR",
                accept_downloads=False,
            )
            page = context.new_page()

            if config.linkedin_email and config.linkedin_password:
                self._login(page)

            offers = self._scrape_jobs(page, query, location, max_results)
            browser.close()

        return offers

    def _login(self, page) -> None:
        page.goto("https://www.linkedin.com/login", wait_until="domcontentloaded")
        page.fill("#username", config.linkedin_email)
        page.fill("#password", config.linkedin_password)
        # Sélecteur le plus stable : le bouton submit du formulaire de login
        page.click("button[type='submit'][aria-label]")
        try:
            page.wait_for_url("**/feed/**", timeout=10000)
        except Exception:
            # Soit captcha, soit 2FA, soit redirect inattendu — on continue prudemment
            page.wait_for_timeout(3000)

    def _scrape_jobs(self, page, query: str, location: str, max_results: int) -> list[JobOffer]:
        offers = []
        start = 0
        seen = set()

        while len(offers) < max_results:
            url = (
                f"https://www.linkedin.com/jobs/search/"
                f"?keywords={requests_encode(query)}&location={requests_encode(location)}"
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


def requests_encode(text: str) -> str:
    import urllib.parse
    return urllib.parse.quote_plus(text)
