#!/usr/bin/env python3
"""
Diagnostic WTTJ + Talent.com — À LANCER SUR TA MACHINE (accès réseau requis).

    cd auto-emploi
    python diag_scrapers.py

Copie-colle TOUTE la sortie : elle me dit exactement pourquoi ces deux sources
renvoient 0 offre (identifiants Algolia périmés ? index erroné ? blocage
anti-bot ? sélecteurs HTML obsolètes ?). Ce fichier est jetable — on le
supprimera après correction.
"""
import json
import urllib.parse

QUERY = "ingénieur"
LOCATION = ""

print("=" * 70)
print("1) WELCOME TO THE JUNGLE — API Algolia")
print("=" * 70)

import os
APP_ID = os.environ.get("WTTJ_ALGOLIA_APP_ID", "CSEKHVMS53").strip()
API_KEY = os.environ.get("WTTJ_ALGOLIA_API_KEY", "02d2eef2400a39e26d764e2b50522f31").strip()
INDEX = os.environ.get("WTTJ_ALGOLIA_INDEX", "wttj_jobs_production_published_at_desc").strip()
print(f"App ID : {APP_ID}")
print(f"API key: {API_KEY[:8]}…")
print(f"Index  : {INDEX}")

try:
    import requests
    url = f"https://{APP_ID.lower()}-dsn.algolia.net/1/indexes/*/queries"
    params = urllib.parse.urlencode({"query": QUERY, "hitsPerPage": 3, "page": 0})
    body = json.dumps({"requests": [{"indexName": INDEX, "params": params}]})
    r = requests.post(
        url,
        data=body,
        headers={
            "X-Algolia-Application-Id": APP_ID,
            "X-Algolia-API-Key": API_KEY,
            "Content-Type": "application/json",
        },
        timeout=20,
    )
    print(f"\nHTTP {r.status_code}  ({len(r.content)} octets)")
    print("Corps (1500 premiers caractères) :")
    print(r.text[:1500])
    try:
        data = r.json()
        res = (data.get("results") or [{}])[0]
        print(f"\n→ nbHits={res.get('nbHits')}  nbPages={res.get('nbPages')}  "
              f"hits dans cette page={len(res.get('hits') or [])}")
        hits = res.get("hits") or []
        if hits:
            print("→ Clés du 1er hit :", sorted(hits[0].keys()))
    except Exception as e:
        print(f"(JSON illisible : {e})")
except Exception as e:
    print(f"ÉCHEC requête Algolia : {type(e).__name__}: {e}")

print()
print("=" * 70)
print("2) TALENT.COM — page HTML")
print("=" * 70)

domain = "fr.talent.com"
page_url = f"https://{domain}/jobs?" + urllib.parse.urlencode(
    {"k": QUERY, "l": LOCATION, "p": 1}
)
print(f"URL : {page_url}")

html = None
status = None
how = None
HEADERS = {
    "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 "
                  "(KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36",
    "Accept-Language": "fr-FR,fr;q=0.9",
    "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
}

# a) cloudscraper
try:
    import cloudscraper
    s = cloudscraper.create_scraper(
        browser={"browser": "chrome", "platform": "windows", "mobile": False}
    )
    r = s.get(page_url, timeout=25)
    status, how = r.status_code, "cloudscraper"
    if r.status_code == 200:
        html = r.text
    print(f"cloudscraper → HTTP {r.status_code}  ({len(r.content)} octets)")
except ImportError:
    print("cloudscraper non installé — fallback requests")
except Exception as e:
    print(f"cloudscraper a échoué : {type(e).__name__}: {e}")

# b) requests
if html is None:
    try:
        import requests
        r = requests.get(page_url, headers=HEADERS, timeout=25)
        status, how = r.status_code, "requests"
        if r.status_code == 200:
            html = r.text
        print(f"requests → HTTP {r.status_code}  ({len(r.content)} octets)")
    except Exception as e:
        print(f"requests a échoué : {type(e).__name__}: {e}")

if html is None:
    print("\n→ Impossible de récupérer le HTML sans navigateur "
          "(probable blocage Cloudflare). Le scraper utilisera Playwright.")
else:
    from bs4 import BeautifulSoup
    import re
    soup = BeautifulSoup(html, "html.parser")

    ld = soup.find_all("script", attrs={"type": "application/ld+json"})
    print(f"\nBlocs JSON-LD : {len(ld)}")
    nb_jobposting = 0
    for sc in ld:
        if sc.string and "JobPosting" in sc.string:
            nb_jobposting += 1
    print(f"Blocs contenant 'JobPosting' : {nb_jobposting}")
    if ld:
        print("Aperçu du 1er bloc JSON-LD (800 car.) :")
        print((ld[0].string or "")[:800])

    cards = soup.find_all(class_=re.compile(r"\bcard\b"))
    print(f"\nÉléments avec classe 'card' : {len(cards)}")
    # Toutes les classes qui ressemblent à des cartes d'offre
    job_classes = set()
    for el in soup.find_all(attrs={"class": True}):
        for c in el.get("class", []):
            if re.search(r"card|job|offer|result|posting|vacan", c, re.I):
                job_classes.add(c)
    print("Classes candidates (card/job/offer/result/posting) :")
    print(", ".join(sorted(job_classes)[:60]) or "(aucune)")

    # Titre de la page pour repérer une page d'erreur / captcha
    title = soup.find("title")
    print(f"\n<title> : {title.get_text(strip=True) if title else '(aucun)'}")

print()
print("=" * 70)
print("FIN DU DIAGNOSTIC — colle toute cette sortie dans le chat.")
print("=" * 70)
