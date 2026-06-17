#!/usr/bin/env python3
"""
Diagnostic Talent.com (v4) — structure JSON des offres dans le payload __next_f.

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
print("TALENT.COM — payload __next_f (RSC)")
print("=" * 70)
print(f"GET {page_url}")
r = make_session().get(page_url, timeout=30)
html = r.text
print(f"HTTP {r.status_code}  ({len(html)} octets)\n")

# 1) Décodage des chunks self.__next_f.push([1,"...."])
chunks = re.findall(r'self\.__next_f\.push\(\[1,\s*("(?:[^"\\]|\\.)*")\]\)', html, re.S)
print(f"Chunks __next_f trouvés : {len(chunks)}")
payload = ""
for c in chunks:
    try:
        payload += json.loads(c)
    except Exception:
        pass
print(f"Payload décodé : {len(payload)} caractères\n")

target = payload if payload else html  # repli : html brut (JSON échappé)

# 2) Noms de clés candidates présentes autour des offres
keys = ["jobTitle", "title", "company", "employer", "companyName", "city",
        "location", "jobId", "newId", "id", "salary", "contractType",
        "employmentType", "datePosted", "postedAt", "url", "applyUrl",
        "description", "snippet"]
print("Clés présentes dans le payload :")
for k in keys:
    n = target.count(f'"{k}"')
    if n:
        print(f'  "{k}" : {n}×')

# 3) Combien d'offres ? (on compte un identifiant qui se répète)
ids = re.findall(r'"(?:newId|jobId)"\s*:\s*"(\d+)"', target)
print(f"\nIdentifiants d'offres (newId/jobId) : {len(ids)} (uniques : {len(set(ids))})")

# 4) Contexte JSON autour de la 1re offre connue
title = "INGENIEUR ENVIRONNEMENT ET ENERGIE"
idx = target.find(title)
if idx == -1:  # titre échappé ?
    idx = target.find(title.split()[0])
if idx != -1:
    start = max(0, idx - 400)
    print(f"\n--- Contexte JSON autour de la 1re offre (1800 car.) ---")
    print(target[start:start + 1800])
    print("--- fin ---")
else:
    print("\n(Titre non retrouvé dans le payload — colle quand même le reste.)")

print()
print("=" * 70)
print("FIN — colle toute cette sortie.")
print("=" * 70)
