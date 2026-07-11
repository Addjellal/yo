"""
Utilitaire Playwright pour contourner Cloudflare avec un vrai navigateur Chromium.

Usage :
    from job_scrapers._browser import fetch_html, BrowserSession

Prérequis :
    pip install playwright
    python -m playwright install chromium
"""
import logging
import os
import sys
import urllib.parse

_LOG = logging.getLogger("job_scrapers.browser")

_UA = (
    "Mozilla/5.0 (Windows NT 10.0; Win64; x64) "
    "AppleWebKit/537.36 (KHTML, like Gecko) "
    "Chrome/136.0.0.0 Safari/537.36"
)


def _launch_args() -> list[str]:
    """Le sandbox Chromium est notre isolation face aux pages web hostiles :
    on ne le désactive que sous root Linux, où Chromium refuse de démarrer."""
    args = ["--disable-blink-features=AutomationControlled"]
    if sys.platform.startswith("linux") and hasattr(os, "geteuid") and os.geteuid() == 0:
        args.append("--no-sandbox")
    return args


def _is_http_url(url: str) -> bool:
    try:
        parsed = urllib.parse.urlparse(url)
    except ValueError:
        return False
    return parsed.scheme in ("http", "https") and bool(parsed.netloc)


def _is_available() -> bool:
    try:
        from playwright.sync_api import sync_playwright  # noqa: F401
        return True
    except ImportError:
        return False


def _new_context(browser):
    return browser.new_context(
        user_agent=_UA,
        locale="fr-FR",
        viewport={"width": 1366, "height": 768},
        accept_downloads=False,  # un scraper n'a aucune raison de télécharger des fichiers
    )


def fetch_html(url: str, wait: str = "domcontentloaded", extra_ms: int = 1500) -> str | None:
    """Fetch une URL avec Chromium headless. Retourne le HTML rendu ou None."""
    if not _is_available() or not _is_http_url(url):
        return None
    try:
        from playwright.sync_api import sync_playwright
        with sync_playwright() as pw:
            browser = pw.chromium.launch(headless=True, args=_launch_args())
            # finally : on ferme le navigateur même si goto/content lève, sinon
            # un processus Chromium reste orphelin à chaque échec de fetch.
            try:
                page = _new_context(browser).new_page()
                page.goto(url, wait_until=wait, timeout=30000)
                if extra_ms:
                    page.wait_for_timeout(extra_ms)
                return page.content()
            finally:
                browser.close()
    except Exception as e:
        # Sans trace, un crash Chromium répété est indiscernable de 0 résultat.
        _LOG.info("fetch_html échoué (%s) : %s", type(e).__name__,
                  urllib.parse.urlparse(url).netloc)
        return None


class BrowserSession:
    """Session Playwright réutilisable pour plusieurs pages (évite de relancer Chromium)."""

    def __init__(self):
        self._pw = None
        self._browser = None
        self._page = None

    def start(self) -> bool:
        if not _is_available():
            return False
        try:
            from playwright.sync_api import sync_playwright
            self._pw = sync_playwright().start()
            self._browser = self._pw.chromium.launch(headless=True, args=_launch_args())
            self._page = _new_context(self._browser).new_page()
            return True
        except Exception as e:
            _LOG.info("lancement Chromium échoué : %s", type(e).__name__)
            return False

    @property
    def ready(self) -> bool:
        return self._page is not None

    def fetch(self, url: str, wait: str = "domcontentloaded", extra_ms: int = 1500) -> str | None:
        if not self._page or not _is_http_url(url):
            return None
        try:
            self._page.goto(url, wait_until=wait, timeout=30000)
            if extra_ms:
                self._page.wait_for_timeout(extra_ms)
            return self._page.content()
        except Exception as e:
            _LOG.info("fetch échoué (%s) : %s", type(e).__name__,
                      urllib.parse.urlparse(url).netloc)
            return None

    def close(self):
        # Fermeture en deux temps : si browser.close() lève (driver déjà mort),
        # pw.stop() doit quand même s'exécuter — sinon le processus node du
        # driver Playwright reste orphelin.
        try:
            if self._browser:
                self._browser.close()
        except Exception:
            pass
        try:
            if self._pw:
                self._pw.stop()
        except Exception:
            pass

    def __enter__(self):
        self.start()
        return self

    def __exit__(self, *_):
        self.close()
