# Toolbox `maintenance-predictive`

```
% Predictive Maintenance Toolbox — pronostic et santé des équipements.
%
%   healthIndicator - Indicateur de santé par analyse en composantes
%   rulSimilarity   - Durée de vie restante par similarité de trajectoire
%   rulDegradation  - Durée de vie restante par extrapolation
%   faultFeatures   - Descripteurs vibratoires usuels
```

## `faultFeatures`

```
FAULTFEATURES Descripteurs vibratoires : efficace, crête, kurtosis, centroïde.
```

## `healthIndicator`

```
HEALTHINDICATOR Indicateur de santé : première composante principale
  des descripteurs, normalisée entre 0 et 1.
```

## `rulDegradation`

```
RULDEGRADATION Durée de vie restante par extrapolation linéaire.
  RUL = RULDEGRADATION(INDICATEUR,SEUIL) rend le nombre de cycles avant
  que la tendance n'atteigne le seuil.
```

## `rulSimilarity`

```
RULSIMILARITY Durée de vie restante par similarité de trajectoires.
  Les trajectoires historiques les plus proches, au sens de l'écart
  quadratique sur la partie commune, votent au prorata de l'inverse de
  leur distance.
```

