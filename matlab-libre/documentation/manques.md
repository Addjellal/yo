# Ce qui manque

Comparaison de l'inventaire de MatLibre aux listes de `documentation/reference-matlab/`.
Fichier produit par `outils/manques.m` ; ne pas le corriger à la main.

| domaine | présentes | manquantes | couverture |
|---|---:|---:|---:|
| automatique | 99 | 9 | 92 % |
| images | 57 | 15 | 79 % |
| matlab-graphique | 126 | 0 | 100 % |
| matlab-langage | 424 | 2 | 100 % |
| optimisation | 26 | 6 | 81 % |
| robuste | 69 | 0 | 100 % |
| signal | 134 | 1 | 99 % |
| statistiques | 187 | 29 | 87 % |
| **ensemble** | **1122** | **62** | **95 %** |

## automatique

`bodeoptions`, `chgFreqUnit`, `chgTimeUnit`, `delayss`, `getBlockValue`
`pidtool`, `sisotool`, `stepDataOptions`, `thiran`

## images

`activecontour`, `adapthisteq`, `hough`, `houghlines`, `houghpeaks`, `im2bw`
`imfindcircles`, `imoverlay`, `impixel`, `mat2gray`, `montage`, `normxcorr2`
`poly2mask`, `roicolor`, `roifilt2`

## matlab-langage

`attributes`, `empty`

## optimisation

`coneprog`, `filterparse`, `optimproblem`, `optimvar`, `prob2struct`, `solve`

## signal

`maxflat`

## statistiques

`anovan`, `copulacdf`, `dataset`, `discardSupportVectors`, `fitcecoc`, `fitclinear`
`fitcnb`, `fitcsvm`, `fitglm`, `fitlme`, `fitrgp`, `fitrlinear`, `fitrsvm`
`fitrtree`, `gmdistribution`, `hmmdecode`, `hmmgenerate`, `hmmtrain`, `lasso`
`manova1`, `mnrfit`, `nnmf`, `pearsrnd`, `polytool`, `relieff`, `rowexch`
`sequentialfs`, `slicesample`, `stepwise`

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
