# Ce qui manque

Comparaison de l'inventaire de MatLibre aux listes de `documentation/reference-matlab/`.
Fichier produit par `outils/manques.m` ; ne pas le corriger à la main.

| domaine | présentes | manquantes | couverture |
|---|---:|---:|---:|
| automatique | 98 | 10 | 91 % |
| images | 57 | 15 | 79 % |
| matlab-graphique | 126 | 0 | 100 % |
| matlab-langage | 346 | 80 | 81 % |
| optimisation | 26 | 6 | 81 % |
| robuste | 32 | 37 | 46 % |
| signal | 104 | 31 | 77 % |
| statistiques | 187 | 29 | 87 % |
| **ensemble** | **976** | **208** | **82 %** |

## automatique

`bodeoptions`, `chgFreqUnit`, `chgTimeUnit`, `delayss`, `frd`, `getBlockValue`
`pidtool`, `sisotool`, `stepDataOptions`, `thiran`

## images

`activecontour`, `adapthisteq`, `hough`, `houghlines`, `houghpeaks`, `im2bw`
`imfindcircles`, `imoverlay`, `impixel`, `mat2gray`, `montage`, `normxcorr2`
`poly2mask`, `roicolor`, `roifilt2`

## matlab-langage

`allchild`, `attributes`, `break`, `builtin`, `celldisp`, `convn`, `empty`
`end`, `fscanf`, `function_handle`, `genvarname`, `inputParser`, `issorted`
`memoize`, `numlock`, `nthargout`, `pagemtimes`, `repelem`, `setxor`, `shiftdim`
`split`, `stack`, `subsasgn`, `swapbytes`, `switch`, `while`, `fileattrib`
`filemarker`, `genpath`, `importdata`, `inputdlg`, `matfile`, `readcell`
`readvars`, `webread`, `websave`, `what`, `writecell`, `between`, `calendar`
`hms`, `isbetween`, `juliandate`, `months`, `posixtime`, `timeofday`, `weeknum`
`yyyymmdd`, `categories`, `countcats`, `discretize`, `groupsummary`, `head`
`histogram2`, `innerjoin`, `ismissing`, `isordinal`, `issortedrows`, `join`
`mergecats`, `movmedian`, `movsum`, `outerjoin`, `pivot`, `removecats`, `renamecats`
`renamevars`, `rmmissing`, `rowfun`, `splitapply`, `splitvars`, `stack`
`standardizeMissing`, `summary`, `table2array`, `table2cell`, `table2struct`
`tail`, `unstack`, `varfun`

## optimisation

`coneprog`, `filterparse`, `optimproblem`, `optimvar`, `prob2struct`, `solve`

## robuste

`actual2normalized`, `complexify`, `cmsclsyn`, `dksyn`, `dmplot`, `frd`
`genss`, `genmat`, `getNominal`, `hinfstruct`, `icsignal`, `iconnect`, `ltiarray2uss`
`musyn`, `normalized2actual`, `randatom`, `randumat`, `randuss`, `robgain`
`robstab`, `robuststab`, `sisobnds`, `ucomplex`, `ucomplexm`, `udyn`, `ultidyn`
`umat`, `uncertain`, `ureal`, `uss`, `ussdata`, `wcdiskmargin`, `wcgain`
`wcgopt`, `wcnorm`, `wcsens`, `wcunc`

## signal

`bandpass`, `bandstop`, `besselap`, `bilinear`, `bitrevorder`, `buttap`
`cheb1ap`, `cheb2ap`, `convmtx`, `detrend`, `ellipap`, `eqtflength`, `filtic`
`highpass`, `impinvar`, `intfilt`, `invfreqs`, `latc2tf`, `latcfilt`, `lowpass`
`maxflat`, `parzen`, `polyscale`, `pow2db`, `rlevinson`, `stmcb`, `strips`
`tf2latc`, `tf2zpk`, `udecode`, `uencode`

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
- **Classes poignées** (`handle`), événements et écouteurs (`events`,
  `addlistener`, `notify`).
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
- **Interaction à la souris** : `zoom`, `pan`, `rotate3d`, `brush`,
  `datacursormode` sont acceptés sans effet, et `ginput` dit qu'il ne
  peut pas ; les figures ne sont pas cliquables.
- **Format `.fig`** : `savefig` écrit du SVG, `openfig` refuse le format
  de MathWorks.

### Calcul

- **Décomposition de Schur** (`schur`, `ordschur`, `qz`) : elle manque à
  l'algèbre linéaire, et les solveurs de Riccati doivent s'en passer.
- **Matrices creuses** : elles existent, mais les factorisations creuses
  (`chol`, `lu`, `qr` creux) travaillent en dense.
- **Précision variable** (`vpa`) et calcul symbolique complet : la boîte
  Symbolique couvre le dérivé, l'intégré simple et la résolution
  polynomiale, non l'algèbre générale.
