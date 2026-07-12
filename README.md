# Mes projets

Un dossier par projet — chacun avec son propre README, ses dépendances et sa
configuration.

| Projet | Description |
|---|---|
| [`auto-emploi/`](auto-emploi/) | Recherche d'emploi automatisée : interface web locale (`python web.py`), scraping multi-sources, matching IA (Claude Fable 5), lettres de motivation, suivi de candidatures et relances. |
| [`cours-embarque/`](cours-embarque/) | Cours complet systèmes embarqués & bas niveau : fondamentaux, C, C++, Arduino, VHDL/FPGA, Java, assembleur/Rust/RTOS, automates Siemens (TIA Portal) et Schneider (EcoStruxure), plan d'apprentissage sur 12 mois. |

## Démarrer un projet

```bash
cd auto-emploi          # entrer dans le dossier du projet
pip install -r requirements.txt
python main.py --check
```

Chaque projet garde son `.env` et son dossier `output/` à l'intérieur de son
propre dossier — rien ne se mélange.
