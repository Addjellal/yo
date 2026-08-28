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
- **612 fonctions natives** couvrant le MATLAB de base.
- **1066 fonctions de toolbox** réparties en 53 modules, écrites dans le
  langage.
- **Les types de données de MATLAB moderne** : `duration`,
  `calendarDuration`, `datetime`, `categorical`, `table`, `timetable`,
  `containers.Map` et les tableaux creux `sparse`, avec leurs
  constructeurs, leurs conversions et leur affichage.
- **Des solveurs d'équations différentielles, raides et non raides** :
  `ode45`, `ode23`, `ode113`, et pour les problèmes raides `ode15s`
  (BDF à pas et ordre variables, ordre 1 à 5), `ode23s` (Rosenbrock
  modifié (2,3) de Shampine et Reichelt), `ode23t` (trapèzes) et
  `ode23tb` (trapèze puis BDF2). Les jacobiennes sont calculées par
  différences finies quand l'utilisateur ne les fournit pas, chaque pas
  résout un système par Newton. Détection d'événements, matrice de masse,
  sortie dense et `deval` sont là.
- **Un rendu graphique** en SVG : courbes, barres, nuages, tiges,
  escaliers, images, sous-graphes, légendes, échelles logarithmiques.
- **Le calcul parallèle** : un pool de travailleurs indépendants pour
  `parfor`, `spmd` et `parfeval`, avec la classification des variables de
  MATLAB (tranches, réductions, diffusées, temporaires).
- **Un générateur de code C** qui traduit l'arbre syntaxique, propage les
  types et les dimensions, et produit du C sans allocation.
- **Un atelier dans le navigateur** : éditeur avec coloration et points
  d'arrêt, console, explorateur de variables, débogueur pas à pas,
  profileur, concepteur d'applications et éditeur de schémas-blocs.
- **Les fonctions imbriquées** avec partage de l'espace de travail, ce qui
  rend les rappels d'application naturels.
- **Une chaîne d'installation** : scripts de compilation pour Linux,
  macOS et Windows, paquets `.tar.gz`, `.deb` et `.zip`, gestion des
  toolboxes depuis le langage, intégration continue sur les trois
  systèmes.
- **Des tests** : 57 vérifications C++ sur le cœur, dix-sept suites en
  langage MATLAB — dont une qui contrôle un résultat exact par toolbox, une les
  types de données, une le calcul parallèle, une qui compile puis exécute
  le C produit pour le comparer à l'interpréteur — et une vérification de
  l'atelier menée par un vrai navigateur.

## Ce qui n'est pas là

Il faut le dire nettement : **MatLibre ne reproduit pas l'intégralité de
MATLAB**. MATLAB, ce sont plusieurs milliers de fonctions documentées, une
centaine de toolboxes, un environnement graphique complet et des
générateurs de code industriels. Ce dépôt en couvre une part utile, pas la
totalité.

Écarts connus, par ordre d'importance :

1. **L'atelier est dans le navigateur, pas sur le bureau.**
   `matlibre --ide` ouvre un éditeur avec coloration et points d'arrêt,
   une console, un explorateur de variables, un débogueur pas à pas, un
   profileur, un concepteur d'applications qui exécute vraiment ce qu'il
   dessine, et un éditeur de schémas-blocs qui simule. Ce qui manque par
   rapport au bureau MATLAB : pas d'application native, pas d'édition
   collaborative, pas de Live Script (cellules exécutables mêlées au
   texte), pas de comparaison de fichiers, et l'éditeur n'a ni repliement
   de code ni recherche multi-fichiers.
2. **Simulink se dessine et se simule ; Stateflow et Simscape restent des
   solveurs.** L'atelier a un éditeur de schémas-blocs : on glisse les
   dix-sept blocs du solveur, on tire les fils à la souris, et le modèle
   part en `new_system` / `add_block` / `add_line`. La simulation est
   réelle : pas fixe, tri topologique, blocs à état, analyse nodale
   modifiée pour les circuits. Manquent : les sous-systèmes, les bus, le
   pas variable, et les éditeurs graphiques de Stateflow et Simscape.
3. **La génération de code couvre les matrices, les types et les
   complexes, pas tout.** `codegen` travaille sur l'arbre syntaxique et
   propage les types depuis la signature donnée par `-args` : scalaires et
   matrices de taille fixe, `double`, `single`, `int8`..`int64`,
   `uint8`..`uint64`, `logical`, `char`, produit matriciel, transposition,
   indexation, `if`, `for`, `while`, `switch`, `break`, `continue`,
   `return`, une trentaine de fonctions mathématiques, et la saturation
   entière de MATLAB. Les nombres complexes sont traduits : le type
   `matlibre_cplx` — deux `double`, comme le `creal_T` de MATLAB Coder —
   est défini dans l'en-tête produit, et les quatre opérations, la
   puissance, la comparaison, `real`, `imag`, `conj`, `abs`, `angle`,
   `complex`, `isreal`, `sqrt`, `exp`, `log`, `sum`, `prod`, `mean`, le
   produit matriciel et la transposition conjuguée passent par des
   fonctions d'appui écrites au besoin. `'` conjugue, `.'` ne conjugue
   pas ; `<` et `>` comparent les parties réelles et `==` les deux
   parties, comme MATLAB ; `z^n` à exposant entier passe par carrés
   successifs, ce qui rend `(1+2i)^2` exactement `-3+4i`. Comme sous
   MATLAB Coder, une variable qui doit recevoir un complexe se déclare
   avec `complex(...)` : y ranger un complexe sans cela est refusé, avec
   le remède dans le message. Le C produit n'alloue rien et compile sous
   `-Wall -Werror`. Manquent : cellules, structures, objets, complexes
   `single` ou entiers, tableaux de taille variable, `varargin`, la
   récursivité, et les cibles matérielles d'Embedded Coder. Le traducteur
   se réserve le préfixe `mlb_` pour ses indices de boucle, ses
   temporaires et ses accumulateurs ; une variable MATLAB qui le porterait
   est refusée. Ce qui n'est pas traduisible est refusé avec le numéro de
   ligne, jamais approximé.
4. **Les toolboxes couvrent l'essentiel de leur domaine, pas tout.**
   La Signal Processing Toolbox compte 163 fonctions — conception de
   filtres avec choix d'ordre, sections du second ordre, douze fenêtres
   dont Dolph-Tchebychev et Taylor, analyse spectrale à court terme,
   cohérence, rééchantillonnage, cepstres réel et complexe,
   Walsh-Hadamard, transformée en sinus, formes d'onde et modulation,
   prédicats de filtre et conversions entre les quatre représentations
   (transfert, pôles-zéros, état, sections du second ordre), mesures sur
   les signaux à deux états (temps de montée, dépassement, rapport
   cyclique), distorsion (THD, SINAD, SFDR, TOI), prédiction linéaire
   avec toutes les conversions entre autocorrélation, coefficients de
   réflexion, polynôme et fréquences spectrales de raies, quatre
   estimateurs autorégressifs et leurs spectres, fenêtres de Slepian et
   multi-fenêtres de Thomson, et les méthodes à sous-espaces MUSIC et
   vecteurs propres. La conception couvre Butterworth, Chebyshev des deux
   types, elliptique — avec les intégrales et les fonctions elliptiques de
   Jacobi ajoutées au MATLAB de base —, Bessel, l'équi-ondulation de Parks
   et McClellan par échange de Remez, l'ajustement sur gabarit de
   `yulewalk` et l'ajustement sur réponse complexe d'`invfreqz`.
   L'Image Processing Toolbox en compte 123 — filtrage avec
   remplissage des bords, gradient, morphologie complète, régions,
   texture, qualité (PSNR, SSIM). La Control System Toolbox en compte
   76 : construction et conversion des modèles dans les trois
   représentations, réponses temporelles et fréquentielles avec les trois
   diagrammes, toutes les marges — gain, phase, retard —, formes
   échelonnées de commandabilité et d'observabilité, formes modale et
   compagne, réduction d'ordre par troncature équilibrée avec la borne
   d'erreur en deux fois la somme des valeurs singulières de Hankel
   supprimées, et la synthèse : placement de pôles, commande linéaire
   quadratique sous cinq formes, observateur, régulateur complet et
   réglage de PID par la marge de phase. Les deux équations de Riccati
   sont résolues par sous-espace invariant, hamiltonien en continu et
   symplectique en discret, et non par itération. La Communications en
   compte 67 : les modulations numériques usuelles avec leurs
   constellations, de Gray comme binaires, les trois modulations
   analogiques, le codage convolutif complet — treillis construit depuis
   les polynômes, décodage de Viterbi à décision dure ou souple, jusqu'au
   rendement k/n —, les codes en blocs cycliques avec leur table de
   syndromes, les trois familles d'entrelaceurs, et les taux d'erreur
   théoriques sur canal gaussien comme sur canal de Rayleigh avec
   diversité. La logique floue en compte 42 : les onze
   fonctions d'appartenance, l'inférence de Mamdani comme celle de
   Sugeno — plusieurs sorties, conclusions constantes ou affines, les
   cinq opérateurs configurables, la négation dans les prémisses —, la
   lecture et l'écriture des fichiers .fis, l'arithmétique sur les
   nombres flous par coupes de niveau, les c-moyennes floues, la
   classification soustractive de Chiu, les trois générateurs de systèmes
   à partir de données, et l'apprentissage hybride d'ANFIS, qui résout
   exactement la moitié linéaire du problème par moindres carrés.
   La Computer Vision en compte 33 : points
   d'intérêt de Harris, de Shi et Tomasi et FAST, descripteurs HOG et
   LBP, images intégrales et filtrage par boîtes, géométrie épipolaire
   complète — matrice fondamentale par les huit points normalisés ou par
   MSAC, droites épipolaires, triangulation —, formule de Rodrigues dans
   les deux sens, disparité par appariement de blocs, flot optique de
   Lucas et Kanade comme de Horn et Schunck, et l'appariement optimal de
   détections à des pistes par l'algorithme hongrois. Les autres modules
   offrent entre 4 et 19 fonctions, choisies pour être celles qu'on
   appelle d'abord.
   La Wavelet Toolbox en compte 54. Les filtres de Daubechies et les
   symlets sont construits par factorisation spectrale du polynôme de
   Daubechies, à n'importe quel ordre : `wfilters('db4')` rend la table
   publiée à 4e-13 près, et le signe du passe-haut est celui de MATLAB.
   Autour d'eux : la transformée décimée en une et deux dimensions avec
   ses reconstructions partielles, la transformée stationnaire — dont
   l'invariance par translation est exacte —, la transformée à
   chevauchement maximal qui conserve l'énergie, l'analyse
   multirésolution associée, les quatre règles de choix du seuil de
   Donoho et Johnstone, l'estimation robuste du bruit, le débruitage et
   la compression, les quatre signaux d'essai de 1994, les neuf modes de
   prolongement aux bords, et l'algorithme en cascade qui rend les
   fonctions d'échelle et d'ondelette elles-mêmes. Du côté continu :
   chapeau mexicain, Morlet réelle et les huit dérivées de la
   gaussienne, avec les fréquences centrales publiées — 0.25, 0.8125,
   0.2 — retrouvées exactement.
   La Statistics and Machine Learning Toolbox en compte 127 : dix-huit
   lois de probabilité complètes — densité, répartition, quantile,
   tirages, moments, estimation — plus les accès génériques `pdf`,
   `cdf`, `icdf` et `random` par nom de loi. Les quantiles continus
   inversent les fonctions incomplètes natives par dichotomie ; les
   quantiles discrets marchent sur la même répartition que celle
   exportée, si bien que l'aller-retour est exact. Les tirages gamma
   suivent Marsaglia-Tsang, vectorisés : seuls les refusés sont retirés
   au tour suivant.
   La Deep Learning Toolbox apprend les réseaux denses et les réseaux
   convolutifs : `imageInputLayer`, `convolution2dLayer` avec pas et
   remplissage `'same'`, `maxPooling2dLayer`, `averagePooling2dLayer`,
   `flattenLayer`. Les gradients de la convolution sont vérifiés par
   différences finies centrées, à 1e-7 près. Manquent : la convolution
   transposée, les couches groupées, les réseaux récurrents (LSTM, GRU),
   et les réseaux à graphe quelconque — la pile reste une séquence.
   MathWorks en compte plusieurs centaines par toolbox.
5. **Les types de données modernes sont là, mais partiellement.**
   `duration`, `calendarDuration`, `datetime`, `categorical`, `table`,
   `timetable`, `containers.Map` et `sparse` existent avec leurs
   opérations courantes, y compris `stack`, `unstack`, `rows2vars`,
   `mergevars`, `splitvars`, et les sélecteurs `timerange`, `withtol` et
   `vartype`. Les fuseaux horaires de `datetime` appliquent un vrai
   décalage : `tzoffset` et `isdst` répondent juste, changer de fuseau
   décrit le même instant dans une autre heure locale, et l'heure qui se
   répète à l'automne est rattachée à sa première occurrence, comme dans
   MATLAB. Ce n'est pas la base IANA complète : soixante-quatre fuseaux,
   les règles en vigueur depuis 2007, aucun changement historique — mais
   n'importe quel décalage fixe écrit `+05:30` est accepté. Manquent :
   la lecture de feuilles Excel, et les tableaux creux logiques ou
   complexes creux au-delà du stockage.
6. **Le calcul parallèle est réel, mais limité à une machine.** `parfor`,
   `spmd`, `parfeval`, `pararrayfun` et `parcellfun` répartissent le
   travail sur un pool de fils, chacun portant un interpréteur complet et
   son propre espace de travail. Mesuré sur quatre cœurs : 2,99× sur une
   boucle de calcul pur. Ce qui manque : MPI entre machines, le GPU
   (`gpuArray`), les tableaux réellement distribués (`distributed` est
   l'identité), et les échanges entre travailleurs pendant un `spmd`
   (`labSend`, `labReceive`, `gop`). Un corps de `parfor` que la
   classification des variables ne sait pas trancher retombe sur
   l'exécution séquentielle plutôt que d'échouer.
7. **Pas de MEX, pas d'interface Java, pas d'interface Python.** Les
   bibliothèques externes sont branchées à la compilation, pas chargées
   à l'exécution : LAPACK, BLAS, FFTW, SuiteSparse et OpenCV sont
   utilisés s'ils sont trouvés, mais il n'y a pas de moyen d'appeler du
   code natif arbitraire depuis le langage. TensorFlow et PyTorch ne
   sont pas branchés : les réseaux de neurones tournent sur
   l'implémentation interne.
8. **Les solveurs d'EDO ne traitent pas les problèmes
   algébro-différentiels.** `ode45`, `ode15s` et les autres acceptent
   `RelTol`, `AbsTol`, `MaxStep`, `InitialStep`, `Refine`, `Events`,
   `Mass`, `Jacobian`, `JPattern` et, pour `ode15s`, `MaxOrder`.
   `ode45` rend une sortie dense d'ordre cinq — l'interpolant de
   Dormand-Prince —, les solveurs implicites une cubique d'Hermite, et
   `deval` évalue la solution partout à cette précision. Les événements
   sont localisés par dichotomie sur l'interpolant, pas au pas près : sur
   une chute libre, l'instant du contact est juste à 1e-9. `JPattern`
   groupe les colonnes disjointes de la jacobienne : sur un système
   tridiagonal de vingt états, le nombre d'évaluations de la fonction est
   divisé par quatre.
   Manquent : la masse singulière, donc les problèmes
   algébro-différentiels, `MStateDependence` et `MvPattern`, `OutputFcn`,
   `NonNegative`, `Vectorized`, et le stockage creux de la jacobienne —
   le motif sert au groupement des colonnes, mais la factorisation reste
   dense. Les tolérances par défaut sont 1e-6 et 1e-9, plus serrées que
   les 1e-3 et 1e-6 de MATLAB. `ode23t` et `ode23tb` estiment leur erreur
   locale en la comparant à un pas d'Euler implicite : l'estimation
   majore l'erreur réelle, donc les pas sont plus courts que nécessaire.
   La variable d'environnement `MATLIBRE_ODE_TRACE` affiche le journal
   des pas acceptés et refusés.
9. **La transformée en ondelettes ne connaît que l'extension
   périodique et deux familles.** `dwt`, `wavedec`, `swt` et `modwt`
   prolongent toujours le signal par périodisation : c'est le mode
   `'per'` de MATLAB, et il n'y a pas de `dwtmode` pour en changer. Les
   longueurs suivent cette convention — `dwt` rend NUMEL(X)/2
   coefficients, là où le mode `'sym'` de MATLAB en rendrait
   FLOOR((N+L-1)/2). Les familles disponibles sont les Daubechies et les
   symlets ; manquent les coiflets, les biorthogonales (`bior`, `rbio`),
   les Meyer discrètes, et les ondelettes complexes. Il n'y a pas de
   paquets d'ondelettes (`wpdec`, `besttree`). La transformée continue
   accepte le chapeau mexicain, Morlet réelle, les huit dérivées de la
   gaussienne et n'importe quelle ondelette discrète, mais pas Morlet
   analytique ni un banc de filtres à Q constant : `cwt` rend les
   coefficients et les pseudo-fréquences, pas le scalogramme d'un banc.
   `wavefun` échantillonne le support [0, L-1] sur 2^ITER*(L-1)+1
   points, avec l'intégrale de la fonction d'échelle exactement à un.

10. **Performance d'un interpréteur à parcours d'arbre** : environ 8 µs par
   instruction scalaire. Les opérations vectorisées, elles, tournent à la
   vitesse du C++.

## Comment vérifier soi-même

```bash
make test              # 57 vérifications C++ + 17 suites en langage MATLAB
make verifier-atelier  # l'atelier, piloté par un vrai navigateur
matlibre --test tests/scripts
```

Les suites ne se contentent pas d'appeler les fonctions : elles comparent
à des valeurs exactes connues — `blsprice(100,100,0.05,1,0.2)` doit rendre
10,4506 ; `butter(2,0.2)` doit rendre les coefficients de la référence ;
`atmosisa(0)` doit rendre 288,15 K et 101 325 Pa.

## Origine du code

Rien n'est repris de MathWorks. Les algorithmes viennent de la littérature
publique — Golub et Van Loan pour l'algèbre linéaire, Cooley-Tukey et
Bluestein pour Fourier, Dormand-Prince et les BDF pour les équations
différentielles,
Nelder-Mead pour l'optimisation sans dérivées, Otsu pour le seuillage,
Needleman-Wunsch et Smith-Waterman pour l'alignement de séquences,
Madgwick pour l'attitude, Pacejka pour le pneumatique — et des
comportements décrits dans la documentation publique de MATLAB, que les
tests reproduisent valeur par valeur.
