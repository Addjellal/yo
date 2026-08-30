# Ce qui manque

Comparaison de l'inventaire de MatLibre aux listes de `documentation/reference-matlab/`.
Fichier produit par `outils/manques.m` ; ne pas le corriger à la main.

| domaine | présentes | manquantes | couverture |
|---|---:|---:|---:|
| automatique | 98 | 10 | 91 % |
| images | 57 | 15 | 79 % |
| matlab-graphique | 62 | 64 | 49 % |
| matlab-langage | 344 | 82 | 81 % |
| optimisation | 26 | 6 | 81 % |
| robuste | 8 | 61 | 12 % |
| signal | 104 | 31 | 77 % |
| statistiques | 118 | 98 | 55 % |
| **ensemble** | **817** | **367** | **69 %** |

## automatique

`bodeoptions`, `chgFreqUnit`, `chgTimeUnit`, `delayss`, `frd`, `getBlockValue`
`pidtool`, `sisotool`, `stepDataOptions`, `thiran`

## images

`activecontour`, `adapthisteq`, `hough`, `houghlines`, `houghpeaks`, `im2bw`
`imfindcircles`, `imoverlay`, `impixel`, `mat2gray`, `montage`, `normxcorr2`
`poly2mask`, `roicolor`, `roifilt2`

## matlab-graphique

`alpha`, `annotation`, `bar3`, `barh`, `boxchart`, `brush`, `caxis`, `clabel`
`comet`, `compass`, `contour3`, `contourf`, `copyobj`, `cylinder`, `datacursormode`
`datetick`, `ezplot`, `fill3`, `findobj`, `fplot`, `fsurf`, `getframe`, `ginput`
`gplot`, `gtext`, `heatmap`, `hidden`, `light`, `lighting`, `material`, `meshc`
`meshz`, `movie`, `newplot`, `pareto`, `patch`, `pie`, `pie3`, `plotmatrix`
`plotyy`, `polar`, `polarplot`, `quiver`, `quiver3`, `rectangle`, `refresh`
`ribbon`, `rose`, `rotate`, `savefig`, `scatter3`, `slice`, `sphere`, `stackedplot`
`stem3`, `surfc`, `surfl`, `surfnorm`, `trimesh`, `trisurf`, `uicontrol`
`voronoi`, `waterfall`, `zoom`

## matlab-langage

`allchild`, `attributes`, `break`, `builtin`, `celldisp`, `convn`, `del2`
`empty`, `end`, `fscanf`, `function_handle`, `genvarname`, `gradient`, `inputParser`
`issorted`, `memoize`, `numlock`, `nthargout`, `pagemtimes`, `repelem`, `setxor`
`shiftdim`, `split`, `stack`, `subsasgn`, `swapbytes`, `switch`, `while`
`fileattrib`, `filemarker`, `genpath`, `importdata`, `inputdlg`, `matfile`
`readcell`, `readvars`, `webread`, `websave`, `what`, `writecell`, `between`
`calendar`, `hms`, `isbetween`, `juliandate`, `months`, `posixtime`, `timeofday`
`weeknum`, `yyyymmdd`, `categories`, `countcats`, `discretize`, `groupsummary`
`head`, `histogram2`, `innerjoin`, `ismissing`, `isordinal`, `issortedrows`
`join`, `mergecats`, `movmedian`, `movsum`, `outerjoin`, `pivot`, `removecats`
`renamecats`, `renamevars`, `rmmissing`, `rowfun`, `splitapply`, `splitvars`
`stack`, `standardizeMissing`, `summary`, `table2array`, `table2cell`, `table2struct`
`tail`, `unstack`, `varfun`

## optimisation

`coneprog`, `filterparse`, `optimproblem`, `optimvar`, `prob2struct`, `solve`

## robuste

`actual2normalized`, `balancmr`, `bstmr`, `complexify`, `cmsclsyn`, `dksyn`
`dmplot`, `frd`, `genss`, `genmat`, `gapmetric`, `getNominal`, `h2hinfsyn`
`h2syn`, `hankelmr`, `hinfstruct`, `icsignal`, `iconnect`, `imp2ss`, `lncf`
`loopmargin`, `ltiarray2uss`, `makeweight`, `modreal`, `mkfilter`, `musyn`
`mussv`, `ncfmargin`, `ncfsyn`, `normalized2actual`, `popov`, `randatom`
`randumat`, `randuss`, `reduce`, `robgain`, `robstab`, `robuststab`, `schurmr`
`sectf`, `sisobnds`, `skewdec`, `slowfast`, `stabproj`, `strans`, `sysbal`
`ucomplex`, `ucomplexm`, `udyn`, `ultidyn`, `umat`, `uncertain`, `ureal`
`uss`, `ussdata`, `wcdiskmargin`, `wcgain`, `wcgopt`, `wcnorm`, `wcsens`
`wcunc`

## signal

`bandpass`, `bandstop`, `besselap`, `bilinear`, `bitrevorder`, `buttap`
`cheb1ap`, `cheb2ap`, `convmtx`, `detrend`, `ellipap`, `eqtflength`, `filtic`
`highpass`, `impinvar`, `intfilt`, `invfreqs`, `latc2tf`, `latcfilt`, `lowpass`
`maxflat`, `parzen`, `polyscale`, `pow2db`, `rlevinson`, `stmcb`, `strips`
`tf2latc`, `tf2zpk`, `udecode`, `uencode`

## statistiques

`anova2`, `anovan`, `bootci`, `boxplot`, `canoncorr`, `chi2gof`, `cluster`
`clusterdata`, `cophenet`, `copulacdf`, `corr`, `dataset`, `dendrogram`
`discardSupportVectors`, `ecdf`, `fitcecoc`, `fitclinear`, `fitcnb`, `fitcsvm`
`fitdist`, `fitglm`, `fitlme`, `fitrgp`, `fitrlinear`, `fitrsvm`, `fitrtree`
`friedman`, `gevcdf`, `gmdistribution`, `gname`, `grp2idx`, `grpstats`, `harmmean`
`histfit`, `hmmdecode`, `hmmgenerate`, `hmmtrain`, `hougen`, `jbtest`, `kruskalwallis`
`kstest2`, `lasso`, `lillietest`, `linkage`, `mahal`, `manova1`, `mdscale`
`mle`, `mnrfit`, `multcompare`, `mvncdf`, `mvnpdf`, `mvnrnd`, `nancov`, `nanmax`
`nanmean`, `nanmedian`, `nanmin`, `nanstd`, `nansum`, `nanvar`, `ncfcdf`
`nctcdf`, `ncx2cdf`, `nlinfit`, `nlparci`, `nnmf`, `normplot`, `normspec`
`pcacov`, `pdist`, `pdist2`, `pearsrnd`, `polyconf`, `polytool`, `princomp`
`probplot`, `procrustes`, `refcurve`, `refline`, `regstats`, `relieff`, `ridge`
`robustfit`, `rowexch`, `runstest`, `sequentialfs`, `signtest`, `slicesample`
`squareform`, `statset`, `stepwise`, `stepwisefit`, `trimmean`, `vartest`
`vartest2`, `wishrnd`, `ztest`

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

- **Rendu 3D avec éclairage** : `light`, `material`, `lighting`, et les
  surfaces qui en dépendent.
- **Objets graphiques de bas niveau** : `line`, `patch`, `rectangle`,
  `annotation`, et le modèle de poignées complet qui va avec.
- **`tiledlayout` / `nexttile`**, la disposition qui remplace `subplot`
  depuis R2019b.
- **Axes polaires**, `polarplot`, `compass`, `rose`.

### Calcul

- **Décomposition de Schur** (`schur`, `ordschur`, `qz`) : elle manque à
  l'algèbre linéaire, et les solveurs de Riccati doivent s'en passer.
- **Matrices creuses** : elles existent, mais les factorisations creuses
  (`chol`, `lu`, `qr` creux) travaillent en dense.
- **Précision variable** (`vpa`) et calcul symbolique complet : la boîte
  Symbolique couvre le dérivé, l'intégré simple et la résolution
  polynomiale, non l'algèbre générale.
