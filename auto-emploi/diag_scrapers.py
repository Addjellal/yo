#!/usr/bin/env python3
"""
Diagnostic Talent.com (v3) — structure de la LISTE d'offres.

    cd auto-emploi
    python diag_scrapers.py

Colle toute la sortie.
"""
import json
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


page_url = "https://fr.talent.com/jobs?" + urllib.parse.urlencode(
    {"k": "ingénieur", "l": "", "p": 1}
)
print("=" * 70)
print("TALENT.COM — structure de la liste d'offres")
print("=" * 70)
print(f"GET {page_url}")

session = make_session()
r = session.get(page_url, timeout=30)
html = r.text
print(f"HTTP {r.status_code}  ({len(html)} octets)\n")

from bs4 import BeautifulSoup
soup = BeautifulSoup(html, "html.parser")

# 1) Tous les liens /view?id= (= les offres de la liste)
view_links = soup.find_all("a", href=re.compile(r"/view\?id="))
print(f"Liens <a href='/view?id='> dans le HTML : {len(view_links)}")
for i, a in enumerate(view_links[:3]):
    print(f"\n--- Lien #{i+1} (HTML, 900 car.) ---")
    # on remonte au conteneur d'offre le plus proche pour voir titre/société
    container = a
    for _ in range(4):
        if container.parent:
            container = container.parent
    print(container.prettify()[:900])

# 2) Combien de JobPosting / d'items dans le JSON-LD ItemList ?
total_items = 0
for sc in soup.find_all("script", attrs={"type": "application/ld+json"}):
    if not sc.string:
        continue
    try:
        data = json.loads(sc.string)
    except Exception:
        continue
    txt = json.dumps(data)
    total_items += txt.count('"@type": "ListItem"') + txt.count('"@type":"ListItem"')
print(f"\nItemList → nb de ListItem : {total_items}")

# 3) Données embarquées dans un payload JS (Next.js app router) ?
for marker in ("__NEXT_DATA__", "self.__next_f", "__NUXT__", "window.__INITIAL"):
    print(f"Présence '{marker}' : {marker in html}")

# 4) Le HTML contient-il les titres des offres en clair (hors carte active) ?
titles = soup.find_all(class_=re.compile(r"JobCard_title__"))
print(f"\nÉléments 'JobCard_title__' : {len(titles)}")
for t in titles[:8]:
    print("  •", t.get_text(strip=True)[:70])

print()
print("=" * 70)
print("FIN — colle toute cette sortie.")
print("=" * 70)
