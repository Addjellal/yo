# Journal des versions

Format inspiré de [Keep a Changelog](https://keepachangelog.com/fr/1.1.0/).
Les dates sont celles de la mise à disposition du contenu.


## Schémas électriques dans les cours

Dix schémas de montage ajoutés, tous produits à partir du catalogue de
composants du simulateur (`simulateur/outils/generer_figures`) : la figure du
cours et le symbole de l'atelier sont donc le même objet.

- **03-arduino** (qui n'avait aucune figure) : LED avec sa résistance série,
  bouton et pull-up interne, pont diviseur, potentiomètre, commande d'un
  moteur par transistor avec diode de roue libre, optocoupleur, afficheur
  7 segments, filtre RC sur une PWM.
- **00-fondamentaux** : montage minimal d'un régulateur 7805.
- **10-stm32** : adaptation de niveau 5 V vers 3,3 V.

## [1.3.0] — Prise en main

### Ajouté
- **Antisèches imprimables** (`antiseches/`) : C, C++, VHDL, Arduino/STM32,
  automates, Git/terminal, conversions & électronique.
- **Glossaire** (`glossaire.md`) : tous les sigles du domaine, plus une
  section « faux amis ».
- **FAQ & dépannage** (`faq-depannage.md`) : les blocages réels par outil
  (compilation, Arduino/Wokwi, GHDL, TIA/PLCSIM, Machine Expert, CubeIDE,
  Java, Git) avec leur solution.
- **Suivi de progression** (`suivi-progression.md`) : tableau de bord à
  imprimer (modules, TP, évaluations, habitudes, portfolio).
- **Outillage** : `Makefile` (`test`, `verif`, `check`, `pdf`, `zip`,
  `clean`) et `_build/verif_liens.py` (vérificateur de liens permanent).
- Fichiers de dépôt : `.editorconfig`, `.gitattributes`, `LICENSE`.

### Corrigé
- Les 19 figures SVG avaient un fond transparent : elles étaient
  **illisibles en mode sombre** sur GitHub. Fond blanc explicite ajouté.
- Les mini-TP n'étaient référencés que depuis le sommaire : chaque cours
  concerné pointe désormais vers le sien.

## [1.2.0] — Parcours d'entrée

### Ajouté
- `parcours-type.md` : 30 premières minutes, boucle de travail illustrée,
  plan sur 30 semaines, carte du dépôt, checklist imprimable.
- Figure `boucle-travail.svg`.
- PDF `00-COMMENCER-ICI.pdf` en tête du dossier `pdf/`.

### Corrigé
- Conflit `text-anchor` (attribut SVG écrasé par le CSS) qui décentrait des
  légendes dans 5 figures.

## [1.1.0] — Simulation et évaluation par plateforme

### Ajouté
- `mini-tp/` : 8 thèmes de programmes **à trous** auto-vérifiants, testables
  sans matériel, avec le hub des liens de simulateurs.
- `evaluations/eval-*.md` : 7 épreuves pratiques adaptées à chaque
  plateforme (recette PLCSIM, projet Wokwi partagé, testbench VHDL exigé,
  table Modbus, preuve débogueur STM32…).
- `RECUEIL-evaluations.pdf`.

### Modifié
- Réorganisation : `cours/` extrait de la racine, `code/st/` scindé en
  `siemens-scl/` et `schneider-st/`, `pdf/` classé par type et ordre de
  lecture.

## [1.0.0] — Formation complète

### Ajouté
- 11 modules de cours (00 fondamentaux → 10 STM32).
- 10 TD avec corrigés détaillés.
- 5 TP guidés déclinés en 18 fiches de séance minutées.
- `code/` : corrigés en projets compilables et testés (C, C++, Java, VHDL,
  Arduino, Python/Modbus, SCL/ST).
- `evaluations/` : QCM de 56 questions corrigé, 3 projets finaux notés.
- `guide-formateur.md`, 18 figures SVG, chaîne de génération PDF.
