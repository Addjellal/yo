# Auto Job Application

Recherche d'emploi automatisée : scraping multi-sources, matching IA entre
votre CV et les offres, génération de lettres de motivation, et suivi
persistant de vos candidatures. **Interface web locale** ou ligne de commande.

## Interface web

```bash
python web.py        # démarre sur http://127.0.0.1:8765 et ouvre le navigateur
```

Aucune dépendance supplémentaire (serveur 100 % bibliothèque standard).
L'interface offre :

- **Recherche** : formulaire complet (CV, pays/région/ville, secteurs, niveau
  d'expérience, sources, mots-clés exclus, score minimum), import de CV en un
  clic, historique des recherches, progression du scan en direct ;
- **Résultats** : cartes avec anneau de score coloré, atouts/lacunes détaillés,
  actions favori / postulée / rejeter, tri, export CSV+JSON, export Notion ;
- **Lettres** : génération dans une modale (3 tons), email d'accompagnement,
  copie en un clic, téléchargement .txt/.pdf ;
- **Suivi** : tableau kanban favoris / postulées / à relancer (>14 jours sans
  réponse) avec actions directes ;
- **Statistiques** : compteurs, candidatures par semaine et par source ;
- **Réglages** : édition des clés API (écrites dans le `.env` local), thème
  sombre/clair.

Sécurité de l'interface web : serveur accessible uniquement depuis
`127.0.0.1`, jeton de session aléatoire anti-CSRF/anti-DNS-rebinding sur
toutes les routes API, Content-Security-Policy stricte, aucun contenu web/LLM
injecté en HTML (textContent uniquement), téléchargements limités au dossier
`output/` avec liste blanche d'extensions (le `.env` et le `.tracker.json`
sont inaccessibles).

## Fonctionnalités

- **Scraping parallèle** : Apec, Adzuna (API), Indeed, Welcome to the Jungle,
  France Travail (API), LinkedIn (mode invité sans compte, ou connecté).
  Contournement Cloudflare silencieux via Chromium headless (Playwright).
- **Matching IA** : score 0–10 par offre, avec raisons + **atouts précis du
  CV** et **lacunes à combler** (visible dans le détail). Pré-filtre par
  mots-clés avant l'appel IA pour économiser les tokens.
- **Apprentissage des préférences** : les offres que vous rejetez (`r N`)
  pénalisent automatiquement les offres similaires aux scans suivants.
- **Mots-clés éliminatoires** : `--exclude "senior,anglais courant"` (ou
  `EXCLUDE_KEYWORDS` dans `.env`) écarte les offres avant l'analyse IA.
- **Filtre niveau d'expérience** : stage/alternance, junior, confirmé,
  senior, expert — pré-filtre instantané (titre/contrat incompatibles) puis
  pénalisation IA des niveaux inadaptés. `--experience junior` ou sélection
  interactive (commande `e` en session).
- **Localisation pays → région → ville** : sélecteur interactif avec
  recherche par texte (sans accents : « bret » → Bretagne) et option `all`
  à chaque niveau. 12 pays (Adzuna et Indeed basculent automatiquement sur
  le bon pays ; Apec/France Travail restent France). Commande `v` en cours
  de session pour changer de lieu, ou `--location "Lyon" --country fr`.
- **Deux providers IA** :
  - `anthropic` — Claude Fable 5 par défaut (sorties JSON structurées
    garanties, OCR haute résolution des CV scannés) ;
  - `ollama` — 100 % local et gratuit (llama3.2 + modèle vision).
- **Lettres de motivation** : 3 tons au choix (standard, formelle, directe),
  **email d'accompagnement** (objet + corps) inclus, variation automatique
  par rapport à vos candidatures passées. Export TXT + PDF.
- **Mode veille** `--watch 60` : re-scanne toutes les heures, n'affiche que
  les nouvelles offres et envoie une **notification desktop**.
- **Relances** : `--stats` liste les candidatures sans réponse depuis plus
  de 14 jours.
- **Tracking persistant** : favoris (`f`), postulées (`a`), rejetées (`r`) —
  les offres déjà traitées ne réapparaissent plus. Écriture atomique.
- **Exports** : JSON + CSV (Excel / Google Sheets) et **Notion** (`--notion`).

## Installation

```bash
cd auto-emploi
pip install -r requirements.txt
python -m playwright install chromium   # contournement Cloudflare (optionnel mais recommandé)
cp .env.example .env                    # puis remplissez vos clés
python main.py --check                  # diagnostic complet
```

## Usage

```bash
python web.py                                         # interface web (recommandé)
python main.py --cv mon_cv.pdf --scan                 # scanner sans postuler
python main.py --cv mon_cv.pdf --query "data engineer" --location "Paris"
python main.py --cv mon_cv.pdf --query "robotique" --watch 60   # veille + notifications
python main.py --cv mon_cv.pdf --scan --exclude "senior,5 ans"  # filtres éliminatoires
python main.py --stats                                # historique + relances à faire
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
