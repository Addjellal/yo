# Toolbox `navigation`

```
% Navigation Toolbox — localisation et planification.
%
%   haversine   - Distance orthodromique entre deux points
%   azimuthTo   - Cap initial entre deux points
%   ekfPredict, ekfUpdate - Filtre de Kalman étendu
%   astar       - Plus court chemin sur une grille
%   dwaStep     - Un pas d'évitement d'obstacle
```

## `astar`

```
ASTAR Plus court chemin sur une grille d'occupation (0 libre, 1 occupé).
  [CHEMIN,COUT] = ASTAR(GRILLE,[i j],[i j]) rend la suite des cases.
```

## `azimuthTo`

```
AZIMUTHTO Cap initial, en degrés depuis le nord.
```

## `ekfPredict`

```
EKFPREDICT Étape de prédiction d'un filtre de Kalman étendu.
  [X,P] = EKFPREDICT(X,P,F,JACOBIENNE,Q) où F est la fonction d'état.
```

## `ekfUpdate`

```
EKFUPDATE Étape de correction d'un filtre de Kalman étendu.
```

## `haversine`

```
HAVERSINE Distance orthodromique entre deux points, en mètres.
```

