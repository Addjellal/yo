# Mes projets

Un dossier par projet — chacun avec son propre README, ses dépendances et sa
configuration.

| Projet | Description |
|---|---|
| [`auto-emploi/`](auto-emploi/) | Recherche d'emploi automatisée : scraping multi-sources, matching IA (Claude Fable 5), lettres de motivation, suivi de candidatures et relances. |

## Démarrer un projet

```bash
cd auto-emploi          # entrer dans le dossier du projet
pip install -r requirements.txt
python main.py --check
```

Chaque projet garde son `.env` et son dossier `output/` à l'intérieur de son
propre dossier — rien ne se mélange.
