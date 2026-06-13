# Auto Job Application

Recherche d'emploi automatisée : scraping multi-sources, matching IA entre
votre CV et les offres, génération de lettres de motivation, et suivi
persistant de vos candidatures. **Interface web locale** ou ligne de commande.

## Interface web

```bash
python web.py        # démarre sur http://127.0.0.1:8765 et ouvre le navigateur
```

Aucune dépendance supplémentaire (serveur 100 % bibliothèque standard).
Identité visuelle dédiée (palette émeraude/ambre, typographie Space Grotesk
auto-hébergée, thème sombre/clair), utilisable sur tablette. Les pages :

- **Recherche** : formulaire complet (pays/région/ville, secteurs, niveau
  d'expérience, sources, mots-clés exclus, score minimum), **sélection
  multi-CV par cases à cocher**, import par bouton ou glisser-déposer
  (**plusieurs fichiers à la fois**, profil analysé par l'IA dès l'import),
  **recherche globale** (intitulés de poste générés par l'IA depuis vos CV),
  plafond d'offres par source **optionnel** (vide = illimité, pensé pour les
  LLM locaux gratuits), progression en direct avec **bouton ⏹ Stopper**
  (les offres déjà scorées sont conservées), re-scoring sans scraper,
  **mode test scraper** (case « sans IA » : collecte et prévisualise les
  offres brutes sans aucun appel IA — ajustez requête et filtres avant de
  reconnecter le matching), bouton « ↺ Recharger la dernière session »
  (offres servies depuis l'historique local, zéro appel API) ;
- **Résultats** : cartes avec anneau + barre de score, badge du **CV
  gagnant** et détail des scores par CV, atouts/lacunes, actions favori /
  postulée / rejeter, tri, export CSV+JSON, export Notion. Cliquer **Ouvrir**
  surligne la carte (la dernière ouverte reste marquée jusqu'au choix d'un
  statut) ; **choisir un statut retire l'offre des résultats** (elle reste dans
  l'onglet Suivi, en tête de colonne). Bouton **« Vérifier la dispo (sans IA) »** :
  reparcourt les offres et teste leur disponibilité réelle sur les plateformes
  par simple requête HTTP (🟢 en ligne / 🔴 retirée / ⚪ indéterminée), zéro appel IA ;
- **Mes CV** : liste des CV importés, **profil structuré extrait par l'IA**
  (coordonnées, compétences catégorisées, expériences, formations, langues),
  formulaire de correction — les modifications manuelles priment sur
  l'extraction pour le matching et les lettres (badge « ✎ modifié
  manuellement » vs « ✓ extrait par l'IA »), bouton « Ré-analyser avec
  l'IA », **suppression avec confirmation** (l'historique garde le nom :
  « CV supprimé : x ») ;
- **Lettres** : page dédiée listant toutes les lettres générées
  (.txt/.pdf) ; génération depuis une offre dans une modale (3 tons), texte
  éditable, email d'accompagnement, copie en un clic ;
- **Historique** : sessions passées (critères, CV utilisés, scores de
  l'époque), rechargement ou relance d'une session ;
- **Suivi** : tableau kanban favoris / postulées / à relancer (>14 jours sans
  réponse) — **glissez-déposez** une carte d'une colonne à l'autre pour
  changer son statut, 🗑 retire l'offre du suivi (elle pourra réapparaître
  aux prochains scans) ;
- **Statistiques** : compteurs, candidatures par semaine et par source ;
- **Réglages** : clés API, routage IA par tâche, coordonnées candidat,
  exemples de style pour les lettres (few-shot), critères par défaut,
  **détection des modèles locaux** (sonde Ollama / LM Studio / llama.cpp,
  mesure RAM/VRAM et conseille un modèle adapté — bouton « Utiliser » pour
  le renseigner en un clic).

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
- **Recherche globale** : l'IA déduit les intitulés de poste depuis vos CV
  et scrape chaque requête (doublons fusionnés) — case à cocher sur le web,
  `--global-search` ou commande `g` en CLI. Combinez avec le plafond
  illimité (`--max 0`, champ vide sur le web) si votre LLM est local.
- **Matching multi-CV** : cochez plusieurs CV (web) ou répétez `--cv` (CLI) —
  chaque offre est scorée avec chaque CV, le meilleur score gagne et le
  détail par CV reste consultable. Pour les lettres, les CV sont fusionnés
  dans le prompt avec leur provenance (pas de doublons ni contradictions).
  Sur les grosses recherches (recherche globale × plusieurs CV), un
  **pré-filtre commun** évite de scorer en détail N× les mêmes offres : un
  seul pré-scoring rapide avec le profil fusionné des CV écarte d'abord les
  offres hors-sujet pour *tous* les CV, puis l'analyse détaillée par CV ne
  porte que sur les meilleures (couverture préservée, coût divisé par ~N).
- **Profils de CV structurés** : extraction IA (coordonnées, compétences
  catégorisées, expériences, formations, langues) éditable dans la page
  « Mes CV » — **vos corrections manuelles priment sur l'extraction** pour
  tous les usages. `--list-cvs` et `--delete-cv NOM` côté CLI (suppression
  irréversible, l'historique garde « CV supprimé : x »).
- **Lettres de motivation** : 3 tons au choix (standard, formelle, directe),
  **email d'accompagnement** (objet + corps) inclus, variation automatique
  par rapport à vos candidatures passées. En multi-CV, la lettre se fonde sur
  le **seul CV le mieux corresp. à l'offre** (le « CV gagnant » affiché sur la
  carte) — prompt plus ciblé, pas de mélange des profils. **Génération en flux
  avec délai** (`LLM_TIMEOUT`) : si l'appel dépasse le délai ou est coupé, le
  texte déjà produit est **récupéré** (lettre partielle, à compléter — l'offre
  n'est alors pas marquée postulée). Export TXT + PDF. **Correction
  typographique automatique** après génération (les petits modèles locaux
  produisent parfois « Îquipe » pour « Équipe », « 2Îme » pour « 2ème » —
  réparé en code pur, sans timeout ni appel IA supplémentaire).
  - **Contrôle de cohérence** : chaque lettre passe par des vérifications
    gratuites (code pur) qui repèrent les marqueurs de gabarit laissés
    (« [Nom] », « XXXX »), un texte tronqué ou un paragraphe dupliqué — les
    points douteux sont signalés dans la modale (bandeau ambre).
  - **Relecture IA optionnelle** (`LETTER_REVIEW=on` ou réglage web) : une
    seconde passe relit le brouillon face au CV et à l'offre et corrige
    uniquement les incohérences factuelles (compétences inventées, mauvaise
    entreprise) et les fautes, sans toucher au style. Routable vers un modèle
    bon marché ou local (`AI_REVIEW_BACKEND`/`AI_REVIEW_MODEL`) — c'est surtout
    utile avec les petits LLM. Conservatrice : la correction n'est adoptée que
    si elle reste plausible (longueur proche, aucun nouveau défaut), sinon le
    brouillon d'origine est conservé. Off par défaut (un appel IA de plus).
  - **Skills de rédaction éditables** : avant chaque génération, le guide
    `prompts/skills/lettre_fr.md` (structure Vous-Moi-Nous, formules,
    erreurs à éviter, mots-clés ATS) ou `cover_letter_en.md` (cover letter
    orientée résultats) est injecté dans le prompt — modifiez ces fichiers
    pour affiner les consignes, ils sont relus à chaque lettre.
  - **Exemples de style (few-shot)** : `LETTER_EXAMPLES=on` réutilise vos
    deux dernières lettres (par langue) comme référence de ton.
  - Détection automatique de la langue de l'offre (FR/EN).
- **Mode veille** `--watch 60` : re-scanne toutes les heures, n'affiche que
  les nouvelles offres et envoie une **notification desktop**.
- **Relances** : `--stats` liste les candidatures sans réponse depuis plus
  de 14 jours.
- **Tracking persistant** : favoris (`f`), postulées (`a`), rejetées (`r`) —
  les offres déjà traitées ne réapparaissent plus. Écriture atomique.
- **Exports** : JSON + CSV (Excel / Google Sheets) et **Notion** (`--notion`).
- **Dossier output/ organisé** : `cv/` (CV importés), `offres/brutes/`
  (avant analyse), `offres/analysees/` (exports scorés), `offres/ecartees/`
  (traçabilité de ce qui a été filtré et pourquoi), `lettres/par_offre/`,
  `logs/` (journal `web.log` : cycle de vie des scans et lettres, erreurs
  complètes). Les anciens fichiers à la racine restent lisibles.
- **APIs externes instables** : Apec (500) et Adzuna (503) sont retentées
  avec délais exponentiels (2 s, 4 s, 8 s) ; en cas de panne persistante,
  message clair « erreur côté Apec/Adzuna » + réutilisation du dernier
  résultat réussi de la session si disponible. Ces erreurs viennent des
  serveurs externes : l'application ne peut que retenter et attendre.
- **Prétraitement des offres** : HTML résiduel nettoyé (balises, entités)
  et sections détectées (missions / profil recherché / compétences) mises
  en avant dans le prompt de matching.
- **Détection LLM locaux** : `--scan-models` (CLI) ou bouton dans Réglages —
  liste les modèles installés (Ollama/LM Studio/llama.cpp), détecte RAM et
  VRAM, et suggère un modèle adapté (tinyllama → mistral → mixtral).

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
python main.py --cv a.pdf --cv b.pdf --scan           # matching multi-CV (meilleur score)
python main.py --cv mon_cv.pdf --global-search --scan # requêtes générées par l'IA depuis le CV
python main.py --cv mon_cv.pdf --scan --max 0         # sans plafond d'offres (LLM local conseillé)
python main.py --cv mon_cv.pdf --query "data engineer" --location "Paris"
python main.py --cv mon_cv.pdf --query "robotique" --watch 60   # veille + notifications
python main.py --cv mon_cv.pdf --scan --exclude "senior,5 ans"  # filtres éliminatoires
python main.py --no-ai --query "data engineer" --scan # test scraper : offres brutes, zéro appel IA
python main.py --scan-models                          # détecter Ollama/LM Studio + suggestions
python main.py --cv mon_cv.pdf --rescore              # re-scorer la base sans scraper
python main.py --sessions                             # sessions passées (+ --session N, --rerun N)
python main.py --list-cvs                             # CV connus du registre
python main.py --delete-cv mon_cv.pdf                 # supprimer un CV (historique conservé)
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
