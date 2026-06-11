# Auto Job Application

Recherche d'emploi automatisée en ligne de commande : scraping multi-sources,
matching IA entre votre CV et les offres, génération de lettres de motivation,
et suivi persistant de vos candidatures.

## Fonctionnalités

- **Scraping parallèle** : Apec, Adzuna (API), Indeed, Welcome to the Jungle,
  France Travail (API), LinkedIn (optionnel). Contournement Cloudflare
  silencieux via Chromium headless (Playwright) pour Indeed et WTTJ.
- **Matching IA** : score 0–10 par offre, avec raisons. Pré-filtre par
  mots-clés avant l'appel IA pour économiser les tokens.
- **Deux providers IA** :
  - `anthropic` — Claude Fable 5 par défaut (sorties JSON structurées
    garanties, OCR haute résolution des CV scannés) ;
  - `ollama` — 100 % local et gratuit (llama3.2 + modèle vision).
- **Lettres de motivation** : générées par offre, exportées en TXT + PDF.
- **Tracking persistant** : favoris (`f`), postulées (`a`), rejetées (`r`) —
  les offres déjà traitées ne réapparaissent plus. Écriture atomique du
  fichier d'historique.
- **Export** JSON + CSV (Excel / Google Sheets).

## Installation

```bash
pip install -r requirements.txt
python -m playwright install chromium   # contournement Cloudflare (optionnel mais recommandé)
cp .env.example .env                    # puis remplissez vos clés
python main.py --check                  # diagnostic complet
```

## Usage

```bash
python main.py --cv mon_cv.pdf --scan                 # scanner sans postuler
python main.py --cv mon_cv.pdf --query "data engineer" --location "Paris"
python main.py --stats                                # historique des candidatures
```

Commandes en mode navigation : `3` détail · `o 3` ouvrir · `f 1-5` favoris ·
`a 2,4` postulées · `r all` tout rejeter · `l` relister · Entrée pour quitter.

## Configuration IA

Dans `.env` :

```ini
PROVIDER=anthropic
ANTHROPIC_API_KEY=sk-ant-...
ANTHROPIC_MODEL=claude-fable-5     # ou claude-sonnet-4-6 (plus économique)
```

ou en local :

```ini
PROVIDER=ollama
OLLAMA_MODEL=llama3.2
OLLAMA_VISION_MODEL=qwen3-vl:4b
```

## Sécurité

**Secrets et données personnelles**
- `.env` n'est jamais commité (`.gitignore`), est écrit de façon atomique et
  créé en permissions `600` (propriétaire seul) sur Linux/macOS.
- Les valeurs écrites dans `.env` sont validées (liste blanche de clés,
  neutralisation des retours à la ligne → pas d'injection de variables).
- Les clés Adzuna sont expurgées des messages d'erreur réseau (l'URL d'une
  erreur HTTP contiendrait sinon `app_key=...` en clair).
- Le cache du CV et l'historique de candidatures passent en permissions `600`.

**Données du web = données hostiles**
- Tous les champs d'une offre sont sanitisés dès le scraping : caractères de
  contrôle supprimés, longueurs bornées, URLs limitées à `http(s)` (un lien
  `javascript:` ou `file:` devient vide).
- Tout affichage console de contenu web ou LLM est échappé : aucune offre ne
  peut injecter du balisage Rich (faux badges « postulée », liens déguisés…).
- Export CSV protégé contre l'injection de formules Excel/Sheets (`=`, `+`,
  `-`, `@` en début de cellule).
- Le texte des offres est isolé dans le prompt (balises XML) et le modèle a
  pour consigne d'ignorer toute instruction qu'il contiendrait.
- Flux RSS parsé via `defusedxml` (anti-XXE, anti-billion-laughs).
- Seules les URLs `http(s)` peuvent être ouvertes dans le navigateur.

**Limites et robustesse**
- Sandbox Chromium conservée (désactivée uniquement sous root Linux, où
  Chromium refuse de démarrer sinon) ; téléchargements bloqués.
- Réponses HTTP plafonnées à 10 Mo, pagination plafonnée par source,
  timeouts sur toutes les requêtes.
- Scores IA bornés 0–10, paramètres CLI et d'environnement bornés et validés
  (provider, URLs, noms de modèles).
- Noms de fichiers générés strictement alphanumériques (pas de traversée de
  chemin), historique écrit de façon atomique avec récupération en cas de
  corruption.

## Avertissement

Le scraping de LinkedIn est contraire à leurs CGU — la source est désactivée
par défaut et à utiliser à vos risques. Respectez les conditions d'utilisation
des sites interrogés et les délais entre requêtes (`REQUEST_DELAY`).
