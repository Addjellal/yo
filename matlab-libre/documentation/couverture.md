# Couverture, et ce qui manque

Ce document dit ce que MatLibre fait et ce qu'il ne fait pas. Il vaut
mieux le lire avant de s'appuyer dessus.

## Ce qui est là

- **Le langage**, dans son usage courant : tous les types de données, les
  opérateurs avec leurs priorités documentées, l'indexation sous toutes
  ses formes, les fonctions et sous-fonctions, les fonctions anonymes avec
  capture, `classdef` en sémantique de valeur avec surcharge d'opérateurs,
  le contrôle de flux, `try/catch` avec identifiants d'erreur, `global` et
  `persistent`, les listes séparées par des virgules.
- **561 fonctions natives** couvrant le MATLAB de base.
- **463 fonctions de toolbox** réparties en 52 modules, écrites dans le
  langage.
- **Les types de données de MATLAB moderne** : `duration`,
  `calendarDuration`, `datetime`, `categorical`, `table`, `timetable`,
  `containers.Map` et les tableaux creux `sparse`, avec leurs
  constructeurs, leurs conversions et leur affichage.
- **Un rendu graphique** en SVG : courbes, barres, nuages, tiges,
  escaliers, images, sous-graphes, légendes, échelles logarithmiques.
- **Des tests** : 57 vérifications C++ sur le cœur, et sept suites en
  langage MATLAB dont une qui contrôle un résultat exact par toolbox et
  une qui contrôle les types de données valeur par valeur.

## Ce qui n'est pas là

Il faut le dire nettement : **MatLibre ne reproduit pas l'intégralité de
MATLAB**. MATLAB, ce sont plusieurs milliers de fonctions documentées, une
centaine de toolboxes, un environnement graphique complet et des
générateurs de code industriels. Ce dépôt en couvre une part utile, pas la
totalité.

Écarts connus, par ordre d'importance :

1. **Pas d'interface graphique de bureau.** Pas d'éditeur intégré, pas
   d'App Designer, pas d'explorateur de variables cliquable, pas d'éditeur
   de schéma Simulink. L'interpréteur est en ligne de commande ; les
   figures sortent en SVG. `who`, `whos`, `dbstop` et `profile` existent
   sous forme de commandes, pas de fenêtres.
2. **Simulink, Stateflow et Simscape sont des solveurs, pas des
   éditeurs.** Un modèle se décrit en appelant `add_block` et `add_line`,
   pas en le dessinant. La simulation, elle, est réelle : pas fixe, tri
   topologique, blocs à état, analyse nodale modifiée pour les circuits.
3. **La génération de code est restreinte.** `codegen` traduit en C un
   sous-ensemble volontairement étroit — fonctions scalaires, `if`, `for`,
   `while`, arithmétique. Il signale ce qu'il ne sait pas traduire au lieu
   de produire du C approximatif. Ce n'est pas Embedded Coder.
4. **Les toolboxes couvrent l'essentiel de leur domaine, pas tout.**
   Chaque module offre entre 4 et 27 fonctions, choisies pour être celles
   qu'on appelle d'abord. La Signal Processing Toolbox de MathWorks en
   compte plusieurs centaines.
5. **Les types de données modernes sont là, mais partiellement.**
   `duration`, `calendarDuration`, `datetime`, `categorical`, `table`,
   `timetable`, `containers.Map` et `sparse` existent avec leurs
   opérations courantes. Manquent : les fuseaux horaires réels de
   `datetime` (la propriété `TimeZone` est conservée mais n'applique
   aucun décalage), `stack`/`unstack`, `withtol`/`timerange`,
   `groupsummary` sur plusieurs dimensions, la lecture de feuilles
   Excel, et les tableaux creux logiques ou complexes creux au-delà du
   stockage.
6. **Pas de calcul parallèle réel.** `parfor` et `spmd` s'exécutent
   séquentiellement : le résultat est le même, le temps ne l'est pas.
7. **Pas de MEX, pas d'interface Java, pas d'interface Python.**
8. **Performance d'un interpréteur à parcours d'arbre** : environ 8 µs par
   instruction scalaire. Les opérations vectorisées, elles, tournent à la
   vitesse du C++.

## Comment vérifier soi-même

```bash
make test           # 57 vérifications C++ + 7 suites en langage MATLAB
matlibre --test tests/scripts
```

Les suites ne se contentent pas d'appeler les fonctions : elles comparent
à des valeurs exactes connues — `blsprice(100,100,0.05,1,0.2)` doit rendre
10,4506 ; `butter(2,0.2)` doit rendre les coefficients de la référence ;
`atmosisa(0)` doit rendre 288,15 K et 101 325 Pa.

## Origine du code

Rien n'est repris de MathWorks. Les algorithmes viennent de la littérature
publique — Golub et Van Loan pour l'algèbre linéaire, Cooley-Tukey et
Bluestein pour Fourier, Dormand-Prince pour les équations différentielles,
Nelder-Mead pour l'optimisation sans dérivées, Otsu pour le seuillage,
Needleman-Wunsch et Smith-Waterman pour l'alignement de séquences,
Madgwick pour l'attitude, Pacejka pour le pneumatique — et des
comportements décrits dans la documentation publique de MATLAB, que les
tests reproduisent valeur par valeur.
