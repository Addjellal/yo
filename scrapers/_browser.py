"""
Utilitaire Playwright pour contourner Cloudflare avec un vrai navigateur Chromium.

Usage :
    from scrapers._browser import fetch_html, BrowserSession

Prérequis :
    pip install playwright
    playwright install chromium
"""

_UA = (
    "Mozilla/5.0 (Windows NT 10.0; Win64; x64) "
    "AppleWebKit/537.36 (KHTML, like Gecko) "
    "Chrome/124.0.0.0 Safari/537.36"
)
_ARGS = ["--no-sandbox", "--disable-blink-features=AutomationControlled"]


def _is_available() -> bool:
    try:
        from playwright.sync_api import sync_playwright  # noqa: F401
        return True
    except ImportError:
        return False


def fetch_html(url: str, wait: str = "domcontentloaded", extra_ms: int = 1500) -> str | None:
    """Fetch une URL avec Chromium headless. Retourne le HTML rendu ou None."""
    if not _is_available():
        return None
    try:
        from playwright.sync_api import sync_playwright
        with sync_playwright() as pw:
            browser = pw.chromium.launch(headless=True, args=_ARGS)
            ctx = browser.new_context(user_agent=_UA, locale="fr-FR",
                                      viewport={"width": 1366, "height": 768})
            page = ctx.new_page()
            page.goto(url, wait_until=wait, timeout=30000)
            if extra_ms:
                page.wait_for_timeout(extra_ms)
            html = page.content()
            browser.close()
            return html
    except Exception:
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
            self._browser = self._pw.chromium.launch(headless=True, args=_ARGS)
            ctx = self._browser.new_context(user_agent=_UA, locale="fr-FR",
                                            viewport={"width": 1366, "height": 768})
            self._page = ctx.new_page()
            return True
        except Exception:
            return False

    @property
    def ready(self) -> bool:
        return self._page is not None

    def fetch(self, url: str, wait: str = "domcontentloaded", extra_ms: int = 1500) -> str | None:
        if not self._page:
            return None
        try:
            self._page.goto(url, wait_until=wait, timeout=30000)
            if extra_ms:
                self._page.wait_for_timeout(extra_ms)
            return self._page.content()
        except Exception:
            return None

    def close(self):
        try:
            if self._browser:
                self._browser.close()
            if self._pw:
                self._pw.stop()
        except Exception:
            pass

    def __enter__(self):
        self.start()
        return self

    def __exit__(self, *_):
        self.close()
