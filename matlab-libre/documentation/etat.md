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
| `src/coeur` | lexeur, analyseur, interpréteur, algèbre linéaire | 9 890 |
| `src/bibliotheque` | 653 fonctions natives, en C++ | 18 356 |
| `src/graphique`, `src/console`, `src/bureau` | tracé, console, application de bureau | 5 901 |
| `toolbox` | 2 644 fichiers `.m`, dont 2 088 fonctions publiques | 121 665 |
| `tests` | 34 scripts `.m` et 2 fichiers C++ | 19 860 |
| `exemples` | 53 programmes d'école, un par boîte à outils | 9 132 |

La couverture par rapport à la liste de référence tirée de la
documentation MathWorks est complète : `outils/manques.m` compte **2 162
fonctions attendues, 0 manquante**.

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
  tests, sur les 636 fiches natives et les 2 088 fiches de toolbox, et
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

## 3. État par boîte à outils

Les trois colonnes de mesure sont à 100 % partout ; la colonne
« profondeur » dit ce qui est réellement couvert, et c'est elle qui
distingue une boîte complète d'une boîte esquissée.

| boîte à outils | fonctions | profondeur |
|---|---:|---|
| statistiques | 272 | complète : lois, tests, régression, classification, mélanges, HMM |
| signal | 205 | complète : conception RIF et RII, analogique et numérique, spectres, mesures d'impulsion |
| matlab | 191 | noyau du langage, en complément des 653 natives |
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
| symbolique | 27 | dérivation, intégration, simplification, limites |
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
| Symbolique | dérivation, intégration des formes usuelles, limites, séries de Taylor, jacobienne et hessienne, sortie LaTeX ; la simplification ne réduit que les cas triviaux | factorisation, développement, résolution d'équations |
| Calcul parallèle | `parfor`, `spmd` et `parfeval` s'exécutent vraiment sur un pool de fils ; chaque travailleur est un interpréteur neuf, sans mémoire partagée | tableaux distribués sur plusieurs machines, GPU |
| Grandes matrices creuses | stockage et opérations de base | factorisations creuses, solveurs itératifs |
| Lecture de fichiers | `.mat` v4, v6 et v7, CSV, images PGM et PPM en texte ; un `.mat` v7.3 est reconnu et refusé avec la raison | HDF5, donc `.mat` v7.3 ; PNG, JPEG et TIFF, qui demandent une bibliothèque externe |
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
