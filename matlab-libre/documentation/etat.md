# État des lieux de MatLibre

Ce document dit ce qui est fait, comment on le sait, et ce qui reste. Il
est écrit à la main ; `documentation/audit.md`, lui, est produit par
`outils/audit.m` et donne les chiffres bruts.

## 1. Ce que MatLibre est aujourd'hui

Un interpréteur du langage MATLAB écrit en C++17, et une bibliothèque de
fonctions couvrant le noyau et cinquante-trois boîtes à outils. Rien n'y
reprend de code MathWorks : chaque fonction est écrite d'après la
documentation publique et vérifiée sur la propriété qui la définit.

| partie | contenu | lignes |
|---|---|---:|
| `src/coeur` | lexeur, analyseur, interpréteur, algèbre linéaire | 10 087 |
| `src/bibliotheque` | 673 fonctions natives, en C++ | 19 565 |
| `src/graphique`, `src/console`, `src/bureau` | tracé, console, application de bureau | 5 901 |
| `toolbox` | 2 889 fichiers `.m`, dont 2 208 fonctions publiques | 131 751 |
| `tests` | 41 scripts `.m` et 2 fichiers C++ | 20 842 |
| `exemples` | 53 programmes d'école, un par boîte à outils | 9 132 |

La couverture par rapport à la liste de référence tirée de la
documentation MathWorks est complète : `outils/manques.m` compte **2 320
fonctions attendues, 0 manquante**. La liste elle-même est vivante : une
fonction courante qui n'y figurait pas est une fonction qui n'existait
pas, et cent trente-six ont été ajoutées de cette façon — la famille
moderne des chaînes, les extrema locaux et les ruptures, les méthodes de
Krylov, les estimations de norme et de conditionnement, les graphes, les
résumés par groupe, les vingt-quatre validateurs d'arguments, les solveurs d'équations aux
dérivées partielles et de problèmes aux limites, la géométrie de calcul, les
interpolants, la lecture et l'écriture du XML, les
régions du plan et leurs opérations booléennes.

## 2. Ce qui est vérifié, et comment

Trois questions différentes, trois outils.

**Est-ce présent ?** `outils/manques.m` compare l'existant à
`documentation/reference-matlab/*.txt`, une liste par domaine. Il écrit
`documentation/manques.md`.

**Est-ce documenté ?** `outils/audit.m` mesure, pour chaque boîte à
outils, la part de fonctions dont l'aide dépasse une ligne, celles qui
portent un exemple, et celles qu'un test ou un exemple nomme. Il écrit
`documentation/audit.md`. Les trois colonnes sont à **100 %**.

**Est-ce que ça marche ?** Trois niveaux de contrôle :

- `outils/verifierExemples.m` exécute le bloc « Exemple » de chaque fiche
  `.m`, chacun dans une portée à lui. Il sert à écrire ; il a trouvé
  quatre-vingt-onze exemples cassés dans douze boîtes à outils, presque
  tous employant une variable que personne n'avait définie.
- `tests/scripts/test_aide.m` fait le même contrôle dans la suite de
  tests, sur les 655 fiches natives et les 2 198 fiches de toolbox, et
  exige de surcroît un « Voir aussi » sur chacune.
- `tests/scripts/test_exemples.m` exécute les 53 programmes d'école, qui
  ne se contentent pas d'appeler les fonctions : chacun vérifie ce que la
  théorie prédit.

La règle de vérification est la même partout : **on vérifie la propriété
qui définit la fonction, jamais une constante recopiée**. Le tableau
suivant en donne quelques-unes, prises dans les tests.

| ce qui est vérifié | propriété |
|---|---|
| dynamique du bras plan | matrice de masse, gravité et Coriolis contre la forme close, à 1e-15 |
| dynamique directe et inverse | l'une annule l'autre, à 1e-15 |
| séquences d'Euler | les douze font l'aller-retour à 2e-16 |
| cinématique inverse UR5 | converge en neuf itérations à 1e-7 |
| logarithme de matrice | `expm(logm(A)) = A` à 3e-15 sur un bloc de Jordan |
| matrices de Hadamard | orthogonales à zéro machine pour n ∈ {1,2,4,8,12,16,20,24,32} |
| transformations de bande | -3 dB en Wn pour Butterworth, l'ondulation pour Chebyshev I |
| ondelettes | reconstruction parfaite ; l'énergie des sous-bandes somme à 100 % |
| transformée de Hadamard rapide | conserve l'énergie et s'inverse au facteur N près |
| noyau de machine à vecteurs de support | symétrique, multiplicateurs dans la boîte, contrainte d'égalité tenue |
| couleurs | la matrice sRGB envoie le blanc sur D65 ; les aller-retours reviennent |
| code de Gray | deux symboles voisins ne diffèrent que d'un bit |
| entrelaceur | refuse ce qui n'est pas une permutation |
| Kalman | l'incertitude décroît en prédiction, décroît encore en correction |
| navigation à l'estime | l'erreur croît linéairement ; le filtre la borne |
| chaleur en 1-D (`pdepe`) | le mode propre sin(πx)e^(−π²t) retrouvé ; l'écart divisé par quatre quand les mailles doublent |
| symétries cylindrique et sphérique | les modes exacts J₀(j₀r)e^(−j₀²t) et sin(πr)/r e^(−π²t), à l'ordre deux |
| volumes finis (`pdepe`) | à flux nul aux deux bouts, l'intégrale de u se conserve à 1e-6 |
| problème aux limites (`bvp4c`) | sin retrouvé à 1e-6 ; x³ exactement, la formule étant d'ordre quatre |
| interpolation de `pdeval` | exacte sur les paraboles, valeurs et dérivées, maillage inégal compris |
| triangulation de Delaunay | aucun point dans un cercle circonscrit, à 1e-9 ; les triangles pavent exactement l'enveloppe convexe |
| enveloppe convexe de l'espace | Euler V − E + F = 2 ; 2n − 4 facettes quand tous les points y sont ; volume exact du cube et du tétraèdre |
| forme alpha | à rayon infini, l'aire est celle de l'enveloppe convexe ; deux amas éloignés font deux régions |
| interpolant dispersé | exact sur tout plan, et repasse par les données |
| `pchip` contre `spline` | sur une marche, l'un ne dépasse jamais, l'autre ondule de 0,128 |
| `makima` contre `akima` | sur un palier suivi d'une pente, l'un reste plat, l'autre ondule de 0,074 |
| héritage de classe | une dérivée reçoit propriétés et méthodes, la redéfinition l'emporte, `isa` remonte la chaîne |
| formats d'échange | écrire puis relire rend ce qu'on avait — lignes, XML, JSON, attributs et caractères réservés compris |
| courbe de l'espace | `plot3` garde ses trois coordonnées ; sur une hélice, les points tombent sur le cylindre à 1e-16 |
| opérations booléennes | l'union vaut la somme moins l'intersection ; un carré ôté d'un autre laisse un trou, et le centre du trou n'est plus dedans |
| factorisation symbolique | le produit des facteurs vaut l'expression de départ, en six points choisis |
| racines rationnelles | trouvées exactement par le théorème qui les borne : 6x²−5x+1 rend 1/3 et 1/2, x²+1 n'en rend aucune |
| réécriture symbolique | Euler, Weierstrass et les logarithmes : la forme change, la valeur reste, à la précision machine |
| éléments simples | le produit des termes vaut la fraction de départ, en quatre points choisis |
| dérivées hyperboliques et réciproques | comparées à une différence finie, jamais recopiées d'une table |
| une poignée graphique | dit sa vraie classe ; deux sortes concaténées restent des poignées |
| `onCleanup` | la tâche part au retour normal, au `return` anticipé et sur une erreur ; l'ordre est celui d'une pile ; un échec n'arrête pas les autres |

## 3. État par boîte à outils

Les trois colonnes de mesure sont à 100 % partout ; la colonne
« profondeur » dit ce qui est réellement couvert, et c'est elle qui
distingue une boîte complète d'une boîte esquissée.

| boîte à outils | fonctions | profondeur |
|---|---:|---|
| statistiques | 272 | complète : lois, tests, régression, classification, mélanges, HMM |
| signal | 205 | complète : conception RIF et RII, analogique et numérique, spectres, mesures d'impulsion |
| matlab | 290 | noyau du langage, en complément des 673 natives |
| finance | 148 | complète : indicateurs techniques, portefeuille, actualisation |
| images | 138 | complète : morphologie, filtres, couleur, segmentation, texture |
| ondelettes | 129 | complète : DWT, paquets, MODWT, CWT, débruitage |
| communications | 115 | complète : modulations, codage, canaux, mesures |
| automatique | 108 | complète : représentations, réponses, lieux, correcteurs |
| apprentissage-profond | 76 | couches, entraînement, différentiation automatique |
| robuste | 73 | valeurs singulières, marges, incertitude |
| flou | 70 | Mamdani et Sugeno, ANFIS, partitionnement |
| robotique | 62 | arbre de corps rigides, RNEA, cinématique inverse, mobiles |
| vision | 60 | points d'intérêt, appariement, géométrie épipolaire, flot optique |
| instruments-financiers | 55 | obligations, options, courbes de taux, arbres |
| types | 40 | tables, temps, durées, catégories |
| econometrie, gestion-risques | 31 | ARIMA, GARCH, valeur en risque, grilles de score |
| identification | 27 | ARX, ARMAX, OE, BJ, sous-espace |
| symbolique | 44 | dérivation, intégration, simplification, limites |
| ajustement-courbes | 23 | modèles nommés, surfaces, lissage |
| optimisation, optimisation-globale | 35 | linéaire, quadratique, non linéaire, génétique, recuit |
| interface | 15 | composants et rappels, sans boucle d'événements modale |
| les 30 autres | 2 à 9 | esquisses : les fonctions les plus employées du domaine |

Les boîtes de deux à neuf fonctions — acquisition, aérospatial, audio,
lidar, maintenance prédictive, radar, RF, véhicule… — ne prétendent pas
couvrir leur domaine. Elles en donnent le rouage central, vérifié, et un
programme d'école qui montre à quoi il sert.

## 4. Ce qui reste à faire

| sujet | état | ce qu'il faudrait |
|---|---|---|
| Interface graphique | `interface` rend des poignées et exécute les rappels au fil de l'eau ; il n'y a pas de boucle d'événements modale | une boucle d'événements, pour que `uiwait` attende vraiment |
| Simulink | schémas-blocs à solveur explicite, pas de boucle algébrique | solveur implicite, sous-systèmes, blocs à état discret |
| Simscape | circuits électriques linéaires, continu et transitoire | composants non linéaires, autres domaines physiques |
| Coder | sous-ensemble scalaire et matriciel vers C et C++ | structures, cellules, fonctions imbriquées |
| Symbolique | dérivation — trigonométriques, hyperboliques, réciproques, logarithmes de toute base —, intégration des formes usuelles, limites, séries de Taylor, jacobienne et hessienne, développement, regroupement, forme de Horner, éléments simples, isolement d'une inconnue, réécriture entre familles de fonctions, factorisation sur les rationnels, résolution exacte des polynômes et numérique du reste, sortie LaTeX | factorisation au-delà des racines rationnelles — x⁴+1 reste entier —, décomposition en éléments simples, arithmétique rationnelle exacte, expressions à plusieurs variables dans COLLECT et FACTOR |
| Calcul parallèle | `parfor`, `spmd` et `parfeval` s'exécutent vraiment sur un pool de fils ; chaque travailleur est un interpréteur neuf, sans mémoire partagée | tableaux distribués sur plusieurs machines, GPU |
| Grandes matrices creuses | stockage et opérations de base ; PCG, BICG, CGS, MINRES et GMRES résolvent sans former la matrice ; ICHOL et ILU préconditionnent, SYMRCM, SYMAMD et COLAMD réordonnent | factorisations creuses complètes — LU et Cholesky creux avec leur permutation |
| Lecture de fichiers | `.mat` v4, v6 et v7, CSV, images PGM et PPM en texte ; un `.mat` v7.3 est reconnu et refusé avec la raison | HDF5, donc `.mat` v7.3 ; PNG, JPEG et TIFF, qui demandent une bibliothèque externe |
| Équations aux dérivées partielles | `pdepe` résout le cas parabolique et elliptique en 1-D, en plan, cylindrique et sphérique, par volumes finis et méthode des lignes ; `bvp4c` les problèmes aux limites par collocation d'ordre quatre | maillage adaptatif dans `bvp4c`, qui garde celui qu'on lui donne ; `bvp5c`, `ode15i`, les EDP en deux et trois dimensions |
| Classes | `classdef` complet : propriétés, méthodes, opérateurs surchargés, `subsref`/`subsasgn`, méthodes statiques, événements, héritage simple et multiple avec appel au constructeur du parent, et la réflexion — `methods`, `properties`, `events`, `enumeration`, `metaclass`, `superclasses` | les membres énumérés comme valeurs — seuls leurs noms se relisent —, le destructeur `delete` d'une classe `handle` (`onCleanup` est écrit au niveau de la portée, ce qui couvre son usage mais pas l'effacement d'une variable), les attributs d'accès (`Access`, `SetAccess`) |
| Géométrie du plan | `polyshape` porte les régions percées, les mesures, les transformations et les quatre opérations booléennes par l'algorithme de Greiner et Hormann | la simplification d'un contour qui se recoupe, et le traitement exact des contacts — deux régions qui se touchent sont séparées d'un cheveu, ce qui coûte six chiffres de précision sur ces cas-là |
| Boîtes esquissées | 30 boîtes de 2 à 9 fonctions | les compléter domaine par domaine, en gardant la règle : rien sans test |
| Performance | l'interpréteur est un parcours d'arbre | compilation en bytecode, vectorisation des boucles internes |
| Durée des tests | la suite complète tient en quarante minutes | paralléliser l'exécution des scripts |

Aucun de ces points n'est une régression : ce sont des limites connues,
écrites dans l'aide des fonctions concernées, qui disent ce qu'elles ne
font pas plutôt que de rendre un résultat faux.

## 5. Ce qu'on ne trouvera pas ici

Une fonction qui ment. La règle tenue tout au long est qu'une fonction
qui ne sait pas faire le dit et lève une erreur — `openfig`, `uicontrol`,
`ginput` en sont les exemples — plutôt que de rendre une valeur
vraisemblable. C'est ce qui permet de se fier au reste.
