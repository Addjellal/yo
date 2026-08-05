# Mes projets

Un dossier par projet — chacun avec son propre README, ses dépendances et sa
configuration. Rien ne se mélange : chaque projet garde son `.env` et ses
sorties à l'intérieur de son dossier.

| Projet | Description | Démarrer |
|---|---|---|
| 🎓 [`formation-embarque/`](formation-embarque/) | **Formation complète systèmes embarqués & bas niveau** : 11 modules de cours, 10 TD corrigés, 5 TP guidés (18 fiches de séance), mini-TP sur simulateur, évaluations, ~190 h. Du binaire aux automates Siemens/Schneider, en passant par C, C++, Arduino, VHDL/FPGA, Java et STM32. | [Commencer ici](formation-embarque/parcours-type.md) |
| 💼 [`auto-emploi/`](auto-emploi/) | Recherche d'emploi automatisée : interface web locale, scraping multi-sources, matching IA, lettres de motivation, suivi de candidatures et relances. | [README](auto-emploi/) |

---

## 🎓 Formation systèmes embarqués

Une formation structurée comme un vrai cursus : cours magistraux, travaux
dirigés corrigés, travaux pratiques minutés, évaluations notées — et tout
est faisable **sans matériel** grâce aux simulateurs.

**Par où commencer** selon qui tu es :

| Tu es… | Ouvre en premier |
|---|---|
| 🆕 Nouveau, tu veux apprendre | [`parcours-type.md`](formation-embarque/parcours-type.md) — les 30 premières minutes, la méthode, le plan sur 30 semaines |
| 📖 Pressé, tu veux juste lire | [`pdf/0-recueils/`](formation-embarque/pdf/) — cours complet, TD et TP en 4 gros PDF |
| 🧑‍🏫 Formateur / enseignant | [`guide-formateur.md`](formation-embarque/guide-formateur.md) — planning, matériel, barèmes, conseils d'animation |
| 🔎 Tu cherches un point précis | [`glossaire.md`](formation-embarque/glossaire.md) · [`antiseches/`](formation-embarque/antiseches/) |
| 🧰 Bloqué sur un outil | [`faq-depannage.md`](formation-embarque/faq-depannage.md) |

```bash
cd formation-embarque
make            # liste les commandes disponibles
make verif      # vérifie tous les liens des documents
make test       # compile et exécute tous les corrigés (C, C++, Java, VHDL)
make pdf        # régénère les 70+ PDF
```

Contenu : 11 modules · 10 TD · 5 TP + 18 fiches de séance · 8 mini-TP sur
simulateur · 7 antisèches · QCM 56 questions · 7 épreuves pratiques ·
3 projets finaux · 19 figures · ~70 PDF.

---

## 💼 auto-emploi

```bash
cd auto-emploi
pip install -r requirements.txt
python main.py --check      # vérifier la configuration
python web.py               # interface web locale
```

---

## Licences

Le **code** est sous licence MIT ; le **contenu pédagogique** sous
CC BY-SA 4.0. Voir [`LICENSE`](LICENSE).
