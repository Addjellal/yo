#!/usr/bin/env python3
"""
Diagnostic WTTJ + Talent.com (v2) — À LANCER SUR TA MACHINE (accès réseau requis).

    cd auto-emploi
    python diag_scrapers.py

v2 : on cherche les VRAIS identifiants Algolia de WTTJ (embarqués dans la page)
et on extrait le HTML exact d'une carte Talent.com. Colle toute la sortie.
"""
import re
import urllib.parse

HEADERS = {
    "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 "
                  "(KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36",
    "Accept-Language": "fr-FR,fr;q=0.9",
    "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
}


def make_session():
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


print("=" * 70)
print("1) WTTJ — découverte des identifiants Algolia dans la page")
print("=" * 70)

session = make_session()
search_page = "https://www.welcometothejungle.com/fr/jobs?query=ing%C3%A9nieur"
print(f"GET {search_page}")
try:
    r = session.get(search_page, timeout=30)
    html = r.text
    print(f"HTTP {r.status_code}  ({len(html)} octets)")

    # a) hôte Algolia <app-id>-dsn.algolia.net  → donne directement l'App ID
    hosts = sorted(set(re.findall(r'([A-Za-z0-9]{6,})-dsn\.algolia\.net', html)))
    print(f"\nHôtes *-dsn.algolia.net trouvés : {hosts or '(aucun)'}")

    # b) App ID via clés de config courantes
    app_ids = sorted(set(re.findall(
        r'["\'](?:algoliaAppId|applicationId|appId|ALGOLIA_APP_ID'
        r'|NEXT_PUBLIC_ALGOLIA[A-Za-z_]*?APP[A-Za-z_]*?ID)["\']\s*:\s*["\']([A-Za-z0-9]{6,})["\']',
        html, re.I)))
    print(f"App ID candidats : {app_ids or '(aucun)'}")

    # c) clé de recherche (32 hexa) via clés de config courantes
    keys = sorted(set(re.findall(
        r'["\'](?:algoliaApiKey|apiKey|searchApiKey|searchKey'
        r'|NEXT_PUBLIC_ALGOLIA[A-Za-z_]*?KEY)["\']\s*:\s*["\']([a-f0-9]{32})["\']',
        html, re.I)))
    print(f"Clés API candidates (clé nommée) : {keys or '(aucune)'}")

    # d) toutes les chaînes 32-hexa (la clé publique en fait partie)
    raw_hex = sorted(set(re.findall(r'\b[a-f0-9]{32}\b', html)))
    print(f"Chaînes 32-hexa présentes : {raw_hex[:8] or '(aucune)'}"
          + (" …" if len(raw_hex) > 8 else ""))

    # e) noms d'index
    idx = sorted(set(re.findall(r'["\'](wttj_[A-Za-z0-9_]+)["\']', html)))
    print(f"Index candidats : {idx or '(aucun)'}")

    # f) contexte autour du 1er 'algolia' pour inspection manuelle
    m = re.search(r'.{80}algolia.{200}', html, re.I | re.S)
    if m:
        print("\nContexte autour de 'algolia' :")
        print(m.group(0).replace("\n", " "))
except Exception as e:
    print(f"ÉCHEC : {type(e).__name__}: {e}")

print()
print("=" * 70)
print("2) TALENT.COM — HTML exact d'une carte JobCard")
print("=" * 70)

page_url = "https://fr.talent.com/jobs?" + urllib.parse.urlencode(
    {"k": "ingénieur", "l": "", "p": 1}
)
print(f"GET {page_url}")
try:
    r = session.get(page_url, timeout=30)
    print(f"HTTP {r.status_code}  ({len(r.content)} octets)")
    if r.status_code == 200:
        from bs4 import BeautifulSoup
        soup = BeautifulSoup(r.text, "html.parser")
        cards = soup.find_all(class_=re.compile(r"JobCard_card__"))
        print(f"Cartes 'JobCard_card__' trouvées : {len(cards)}")
        if cards:
            card = cards[0]
            html_card = card.prettify()
            print("\n--- HTML de la 1re carte (2500 car. max) ---")
            print(html_card[:2500])
            print("--- fin carte ---")
            # liens dans la carte
            links = [a.get("href") for a in card.find_all("a", href=True)]
            print(f"\nLiens (href) dans la carte : {links[:5]}")
except Exception as e:
    print(f"ÉCHEC : {type(e).__name__}: {e}")

print()
print("=" * 70)
print("FIN — colle toute cette sortie dans le chat.")
print("=" * 70)
