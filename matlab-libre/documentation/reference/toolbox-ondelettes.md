# Toolbox `ondelettes`

```
% Wavelet Toolbox — analyse en ondelettes.
%
%   wfilters   - Bancs de filtres (haar, db2, db4, sym2)
%   dwt / idwt - Transformée discrète à un niveau
%   wavedec / waverec - Décomposition et reconstruction multiniveaux
%   wthresh    - Seuillage dur ou doux
%   wdenoise   - Débruitage par seuillage universel
%   cwt        - Transformée continue (chapeau mexicain)
%   wenergy    - Répartition de l'énergie par niveau
%
% Décomposition
%   wmaxlev     - Niveau maximal utile
%   appcoef     - Coefficients d'approximation
%   detcoef     - Coefficients de détail d'un niveau
%   dwt2, idwt2 - Transformée bidimensionnelle, un niveau
%   wcodemat    - Mise à l'échelle pour l'affichage
```

## `appcoef`

```
APPCOEF Coefficients d'approximation d'une décomposition WAVEDEC.
  A = APPCOEF(C,L,ONDELETTE) rend l'approximation du dernier niveau.
  A = APPCOEF(C,L,ONDELETTE,N) reconstruit celle du niveau N.
```

## `cwt`

```
CWT Transformée continue par ondelette « chapeau mexicain ».
  C = CWT(X,ECHELLES) rend une ligne de coefficients par échelle.
```

## `detcoef`

```
DETCOEF Coefficients de détail d'un niveau donné.
  D = DETCOEF(C,L,N) extrait le bloc du niveau N dans le vecteur rendu
  par WAVEDEC. Le niveau 1 est le plus fin.

  Exemple :
     [c, l] = wavedec(1:8, 2, 'db1');
     numel(detcoef(c, l, 1))   % 4
```

## `dwt`

```
DWT Transformée en ondelettes discrète, un niveau.
  [A,D] = DWT(X,NOM) rend l'approximation et le détail, sous-échantillonnés
  d'un facteur deux. Les bords sont prolongés périodiquement.
```

## `dwt2`

```
DWT2 Transformée en ondelettes discrète bidimensionnelle, un niveau.
  [CA,CH,CV,CD] = DWT2(X,ONDELETTE) rend l'approximation et les détails
  horizontal, vertical et diagonal. La transformée est séparable : on
  applique DWT aux lignes puis aux colonnes.

  Exemple :
     [a, h, v, d] = dwt2(ones(4), 'db1');   % a = 2*ones(2), h = v = d = 0
```

## `idwt`

```
IDWT Reconstruction à partir de l'approximation et du détail.
```

## `idwt2`

```
IDWT2 Transformée en ondelettes bidimensionnelle inverse, un niveau.
  X = IDWT2(CA,CH,CV,CD,ONDELETTE) reconstruit l'image.
Colonnes d'abord, dans l'ordre inverse de DWT2.
```

## `wavedec`

```
WAVEDEC Décomposition multiniveaux en ondelettes.
  [C,L] = WAVEDEC(X,N,NOM) empile les coefficients : approximation de
  niveau N, puis détails du niveau N au niveau 1. L donne les longueurs.
```

## `waverec`

```
WAVEREC Reconstruction d'une décomposition multiniveaux.
```

## `wcodemat`

```
WCODEMAT Met une matrice à l'échelle des indices de couleur.
  Y = WCODEMAT(X,NBCODES) ramène X dans 1..NBCODES.

  Exemple :  wcodemat([0 1], 4)   % [1 4]
```

## `wdenoise`

```
WDENOISE Débruitage par seuillage universel des détails.
  Y = WDENOISE(X,N,NOM) applique le seuil de Donoho sqrt(2 log n) * sigma,
  sigma étant estimé par l'écart médian absolu des détails de niveau 1.
```

## `wenergy`

```
WENERGY Répartition de l'énergie entre approximation et détails.
```

## `wfilters`

```
WFILTERS Bancs de filtres d'analyse et de synthèse.
  [LO_D,HI_D,LO_R,HI_R] = WFILTERS(NOM) où NOM vaut 'haar', 'db2',
  'db4' ou 'sym2'.
```

## `wmaxlev`

```
WMAXLEV Niveau de décomposition maximal utile.
  N = WMAXLEV(L,ONDELETTE) rend le nombre de niveaux au-delà duquel le
  signal deviendrait plus court que le filtre.

  N = floor(log2(L / (Lf - 1))) où Lf est la longueur du filtre.

  Exemple :  wmaxlev(64, 'db2')   % 4
```

## `wthresh`

```
WTHRESH Seuillage des coefficients d'ondelettes.
  Y = WTHRESH(X,'s',T) applique le seuillage doux, 'h' le seuillage dur.
```

