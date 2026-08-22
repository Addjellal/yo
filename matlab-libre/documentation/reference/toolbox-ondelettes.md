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
```

## `cwt`

```
CWT Transformée continue par ondelette « chapeau mexicain ».
  C = CWT(X,ECHELLES) rend une ligne de coefficients par échelle.
```

## `dwt`

```
DWT Transformée en ondelettes discrète, un niveau.
  [A,D] = DWT(X,NOM) rend l'approximation et le détail, sous-échantillonnés
  d'un facteur deux. Les bords sont prolongés périodiquement.
```

## `idwt`

```
IDWT Reconstruction à partir de l'approximation et du détail.
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

## `wthresh`

```
WTHRESH Seuillage des coefficients d'ondelettes.
  Y = WTHRESH(X,'s',T) applique le seuillage doux, 'h' le seuillage dur.
```

