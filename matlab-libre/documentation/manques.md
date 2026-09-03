# Ce qui manque

Comparaison de l'inventaire de MatLibre aux listes de `documentation/reference-matlab/`.
Fichier produit par `outils/manques.m` ; ne pas le corriger à la main.

| domaine | présentes | manquantes | couverture |
|---|---:|---:|---:|
| automatique | 108 | 0 | 100 % |
| images | 72 | 0 | 100 % |
| matlab-graphique | 126 | 0 | 100 % |
| matlab-langage | 424 | 2 | 100 % |
| ondelettes | 103 | 9 | 92 % |
| optimisation | 31 | 1 | 97 % |
| robuste | 69 | 0 | 100 % |
| signal | 134 | 1 | 99 % |
| statistiques | 216 | 0 | 100 % |
| **ensemble** | **1283** | **13** | **99 %** |

## matlab-langage

`attributes`, `empty`

## ondelettes

`coifwavf`, `cwtfilterbank`, `cwtfreqbounds`, `dtfilters`, `dualtree`, `dwtfilterbank`
`wavemngr`, `wcoherence`, `wsst`

## optimisation

`filterparse`

## signal

`maxflat`

## Ce qui manque au-delà des fonctions

Le tableau ci-dessus compte des noms. Ce qui suit compte davantage : ce
sont les manques de structure, ceux qu'aucune fonction ajoutée ne
comblerait. Ils sont classés par ce qu'ils coûtent à l'utilisateur.

### Formats de fichiers

- **MAT niveau 7.3**. C'est un fichier HDF5, non le format MAT. Il est
  reconnu et l'erreur dit quoi faire — réenregistrer en `-v7` —, mais il
  n'est pas lu. Le lire demanderait un lecteur HDF5 complet.
- **Objets MCOS dans un fichier MAT**. Un `ss`, un `tf`, une `table`
  sauvés par MATLAB sont rangés dans une forme opaque qui renvoie à un
  sous-système du fichier. MatLibre lit la forme, nomme la variable et
  dit ce qu'il n'a pas su reconstruire, mais ne rebâtit pas l'objet.
- **Figures `.fig`**. Ce sont des fichiers MAT portant le modèle d'objets
  graphiques de MathWorks, que MatLibre n'a pas.
- **Modèles Simulink `.slx`**. `sim` existe pour les modèles écrits en
  MatLibre ; le format de MathWorks, non.
- **Scripts vivants `.mlx`**. Le format est une archive OPC ; l'éditeur
  ne les ouvre pas.

### Langage

- **Dossiers `private/`** : les fonctions privées d'un dossier ne sont pas
  reconnues comme telles.
- **Dossiers de paquet `+nom/`** : la notation `paquet.fonction` marche
  pour ce qui est enregistré sous ce nom, non par découverte de dossier.
- **Événements et écouteurs** (`events`, `addlistener`, `notify`) : les
  `events` sont analysés, les écouteurs manquent. Les **classes poignées**
  (`classdef X < handle`), elles, partagent bien leur état : une méthode
  qui écrit dans l'objet se voit depuis toutes ses copies.
- **Héritage** : `classdef X < Y` est analysé, mais seul `handle` a un
  effet ; les méthodes et propriétés du parent ne sont pas héritées.
- **Énumérations** (`enumeration`) dans un `classdef`.
- **`matlab.unittest`** : le cadre de tests à classes. Les tests de
  MatLibre sont des scripts à `assert`.
- **Mots-clés de `classdef`** : `properties`, `methods`, `events` et
  `enumeration` sont sensibles au contexte, comme dans MATLAB — ce sont
  des mots-clés dans un `classdef`, des identificateurs partout ailleurs,
  si bien que `properties(sys)` appelle bien la fonction. En revanche les
  attributs entre parenthèses (`properties (Access = private)`) sont
  analysés et ignorés : rien n'est privé.
- **Interfaces externes** : MEX, appel de Java, de Python, de C++.

### Bureau

- **App Designer et GUIDE** : la construction d'interfaces. `uicontrol`
  et `uifigure` n'existent pas.
- **Éditeur de variables** : le tableau des variables se lit, il ne
  s'édite pas au clavier comme celui de MATLAB.
- **Outils interactifs des figures** : zoom à la souris, curseur de
  données, brosse, rotation 3D.
- **Comparaison de fichiers** (`visdiff`), **analyse de code**
  (`checkcode`, l'analyseur qui souligne dans l'éditeur).

### Graphique

Les noms du tableau ci-dessus sont tous présents ; ce qui suit est ce
qu'ils ne font pas encore comme MATLAB.

- **Rendu tridimensionnel** : le rendu de MatLibre est plan. `surf`,
  `mesh`, `plot3`, `contour3`, `scatter3` et leurs voisins tracent, mais
  sans perspective ; `view`, `light`, `lighting`, `material` et `hidden`
  sont acceptés sans effet. Chaque fiche d'aide le dit.
- **Second axe des ordonnées** : `plotyy` et `yyaxis` remettent la
  seconde courbe à l'échelle de la première au lieu de lui donner ses
  propres graduations à droite.
- **Axes polaires** : `polarplot`, `compass` et `rose` convertissent en
  coordonnées cartésiennes et dessinent eux-mêmes cercles et rayons ; la
  graduation angulaire du cadre manque.
- **Transparence** (`alpha`) et **bandes de `contourf`** : le fond est
  posé en champ continu, non découpé par niveau.
- **`histogram2`** dessine le quadrillage en couleurs — le
  `'DisplayStyle','tile'` de MATLAB — et non les barres en perspective.
- **Interaction à la souris** : `zoom`, `pan`, `rotate3d`, `brush`,
  `datacursormode` sont acceptés sans effet, et `ginput` dit qu'il ne
  peut pas ; les figures ne sont pas cliquables.
- **Format `.fig`** : `savefig` écrit du SVG, `openfig` refuse le format
  de MathWorks.

### Traitement du signal

- **`maxflat`** : le filtre à module maximalement plat d'ordres
  dissymétriques — N zéros en z = −1 et M pôles — n'est pas conçu. Le cas
  N = M est exactement `butter`, qui est là.
- **Objets `digitalFilter`** : `designfilt` et l'objet qu'il rend
  n'existent pas. `lowpass` et ses voisines rendent les coefficients B et
  A au lieu de l'objet.
- **`intfilt`** en bande limitée résout les équations normales d'une
  interpolation idéale, ce qui est la définition ; les coefficients
  peuvent différer de MATLAB au dernier chiffre.

### Images

- **Pas d'objets ni de classes d'image** : une image est une matrice.
  `imref2d`, les objets `roi` (`drawcircle`, `images.roi.*`) et les
  applications interactives — `imtool`, `Color Thresholder`, `Image
  Segmenter` — n'existent pas ; `impixel` et `roipoly` prennent leurs
  points en argument au lieu de les faire cliquer.
- **`edge` façon Canny** : le seuil haut automatique est lu sur
  l'histogramme du gradient — celui qui laisse sept dixièmes des points
  du côté « pas un contour » —, le seuil bas en vaut quatre dixièmes.
  C'est la règle publiée ; les contours peuvent différer d'un pixel de
  ceux de MATLAB sur une image bruitée.
- **`imfindcircles`** ne cherche que par accumulation à deux étapes :
  `'Method'` et `'FilterSize'` sont reçus sans effet, et le mode
  `'PhaseCode'` de MATLAB n'est pas là. Les pics sont retenus au-dessus
  de huit dixièmes du maximum de l'accumulateur, puis dédoublonnés au
  rayon près.
- **`activecontour`** mène l'évolution par différences finies sur une
  fonction de niveau, sans réinitialisation de la distance signée : sur
  un très grand nombre d'itérations le contour peut se figer là où
  MATLAB continue d'avancer.
- **`montage`** assemble et rend l'image assemblée ; la navigation entre
  vignettes n'existe pas.

### Systèmes asservis

- **Pas de retards internes** : MATLAB garde le retard exact dans un
  modèle d'état (`InternalDelay`). `delayss` l'approche par Padé d'ordre
  trois, ce qui est juste en basse fréquence et s'écarte au-delà.
  `thiran`, lui, est exact au sens du retard de groupe plat en zéro.
- **`pidtool` et `sisotool`** ne sont pas interactifs : MatLibre règle le
  correcteur — comme `pidtune` — et trace les vues une fois, là où MATLAB
  ouvre une application à curseurs.
- **Pas de modèle `genss`** : `getBlockValue` lit le bloc dans une
  structure de blocs ou dans un modèle nommé, non dans un modèle à blocs
  réglables.
- **`bodeoptions` et `stepDataOptions`** sont des structures : les champs
  que MatLibre traite sont énumérés dans leur aide, les autres sont
  gardés sans effet pour que le code écrit pour MATLAB s'exécute.

### Optimisation

- **Écriture par problème** : `optimvar`, `optimexpr`, `optimconstr` et
  `optimproblem` couvrent le linéaire, le quadratique et les variables
  entières. Les expressions non linéaires — un produit de trois
  variables, un logarithme — ne sont pas représentées, et `solve` ne sait
  donc pas déléguer à `fmincon` un problème écrit ainsi.
- **`solve` ne rend pas d'objet de sortie** : la solution est une
  structure à un champ par variable, non un `OptimizationResult`.
- **`coneprog`** ramène les contraintes de cône à `fmincon` par
  pénalisation, au lieu d'employer un point intérieur conique : la
  solution est bonne à quelques millièmes, non à la précision machine.
- **`linprog` et `quadprog`** minimisent une barrière logarithmique par
  Nelder-Mead : pas de simplexe, pas de base optimale, donc ni variables
  duales ni analyse de sensibilité.

### Ondelettes

- **Familles construites, non recopiées** : `dbaux`, `symaux` et
  `biorwavf` sortent d'une factorisation spectrale, non d'une table.
  L'accord avec MATLAB est celui de la construction elle-même : exact
  pour les splines biorthogonales, et à la précision machine pour dbN et
  symN jusqu'à l'ordre vingt environ.
- **`bior5.5` et `bior6.8`** ne sont pas des splines : MATLAB les tire
  d'un ajustement au plus près de l'orthonormalité, que MatLibre ne
  reproduit pas. Ces deux noms sont refusés plutôt qu'approchés ; les
  treize autres, `bior4.4` — le couple 9/7 de JPEG 2000 — compris, sont
  là. `coifwavf` et les coiflets manquent pour la même raison.
- **Zéros de complètement** : MATLAB centre les filtres biorthogonaux
  dans un tableau de longueur commune. MatLibre les place là où
  l'alignement des deux filtres l'exige — un décalage impair changerait
  la parité du demi-bande et le repliement ne s'annulerait plus. Les
  coefficients non nuls sont les mêmes, leur position dans le tableau
  peut différer d'un rang.
- **`meyer`** échantillonne par transformée de Fourier inverse sur une
  grille dont le nombre de points doit être une puissance de deux ;
  MATLAB accepte n'importe quelle longueur.
- **Un seul mode de prolongement.** `dwt`, `wavedec` et leurs voisines
  analysent en périodique. `dwtmode` lit et pose le mode, mais refuse
  tout ce qui n'est pas `'per'` au lieu d'analyser autrement que promis ;
  `wextend`, lui, connaît les neuf prolongements.
- **`icwt`** ne rend que ce que les échelles demandées couvrent : la
  composante continue et le hors-bande sont perdus, ce qui est fidèle à
  ce que la transformée a gardé. Là où MATLAB emploie un banc de filtres
  analytique, MatLibre mesure le filtre que forment analyse et somme,
  puis l'inverse dans sa bande — quelques centièmes d'erreur relative
  loin des bords.
- **`wfbmesti`** sous-estime H d'environ cinq centièmes en dessous de
  0,5 : la relation d'échelle ne s'établit qu'aux niveaux grossiers, et
  la régression ne garde que les octaves du milieu.
- **`wvarchg`** choisit le nombre de ruptures avec une pénalité de
  4 log(n), deux fois celle du critère bayésien : celle-ci laissait
  passer une découpe de temps en temps sur du bruit pur.

### Statistiques et apprentissage

- **Objets de modèle** : MATLAB rend des objets — `ClassificationSVM`,
  `GeneralizedLinearModel`, `LinearMixedModel` — à méthodes. MatLibre
  rend des structures portant les mêmes champs, et une fonction `predict`
  commune qui reconnaît le modèle à son champ `type`.
- **`fitlme`** n'ajuste que les intercepts aléatoires — la forme
  `(1|g)` —, avec un ou plusieurs facteurs croisés. Les pentes
  aléatoires, `(x|g)`, et les modèles emboîtés ne le sont pas.
- **Formules de Wilkinson** : seul `fitlme` en lit une, et seulement les
  termes séparés par `+`. `fitlm` et `fitglm` prennent une matrice.
- **`polytool` et `stepwise`** ne sont pas interactifs : MatLibre mène la
  procédure et rend le résultat, là où MATLAB ouvre une fenêtre où l'on
  ajoute et retire les termes à la main.
- **`eig(A,B)`** passe par la réduction de Cholesky quand B est
  symétrique définie positive, et par `B\A` sinon : une matrice B
  singulière — que MATLAB traite par la décomposition QZ, avec des
  valeurs propres infinies — n'est pas admise.

### Robustesse

Les noms sont tous présents ; ce qui suit est ce que la représentation
de MatLibre ne fait pas comme celle de MathWorks.

- **Pas de forme LFT.** MATLAB range une incertitude en transformation
  fractionnaire linéaire, ce qui rend l'analyse mu exacte. MatLibre garde
  la dépendance elle-même — la fonction des paramètres —, ce qui accepte
  une division ou une racine que la forme LFT ne représenterait qu'au
  prix d'un développement. En contrepartie, `wcgain`, `robstab` et leurs
  voisines balaient le domaine — sommets, tirages, descente locale — et
  rendent donc un **minorant** du pire cas, exact quand la dépendance est
  monotone, là où MATLAB rend un majorant par mu. Chaque fiche le dit.
- **`mussv` borne, il ne calcule pas.** La borne haute vient de la mise à
  l'échelle d'Osborne, la borne basse d'une recherche de phase ; elles se
  rejoignent sur un bloc plein et sur une structure diagonale de trois
  blocs au plus, non en général.
- **`dksyn` à D constant.** L'itération D-K emploie une mise à l'échelle
  constante en fréquence, non un ajustement rationnel de D : le
  correcteur trouvé est un peu moins bon, et d'ordre plus bas.
- **`hinfstruct` par le simplexe.** Le réglage d'un correcteur structuré
  passe par Nelder-Mead sur les paramètres, non par la méthode non lisse
  de MATLAB : plus lent, sans garantie d'optimum, mais applicable à
  n'importe quelle structure.
- **`iconnect` n'existe pas.** Les schémas s'assemblent par `sysic` ou
  par `connect`.

### Calcul

- **Décomposition de Schur** (`schur`, `ordschur`, `qz`) : elle manque à
  l'algèbre linéaire, et les solveurs de Riccati doivent s'en passer.
- **Matrices creuses** : elles existent, mais les factorisations creuses
  (`chol`, `lu`, `qr` creux) travaillent en dense.
- **Précision variable** (`vpa`) et calcul symbolique complet : la boîte
  Symbolique couvre le dérivé, l'intégré simple et la résolution
  polynomiale, non l'algèbre générale.
