# Toolbox `antennes`

```
% Antenna Toolbox — rayonnement et réseaux.
%
%   dipolePattern - Diagramme d'un dipôle
%   arrayFactor   - Facteur de réseau linéaire
%   friis         - Bilan de liaison
%   directivity   - Directivité à partir d'un diagramme
%   beamwidth     - Ouverture à -3 dB
```

## `arrayFactor`

```
ARRAYFACTOR Facteur d'un réseau linéaire uniforme.
  AF = ARRAYFACTOR(N,D,THETA,PHASE) pour N éléments espacés de D
  longueurs d'onde, THETA en radians, PHASE le déphasage progressif.
```

## `beamwidth`

```
BEAMWIDTH Ouverture à mi-puissance (-3 dB), en radians.
```

## `dipolePattern`

```
DIPOLEPATTERN Diagramme de rayonnement d'un dipôle de longueur L/lambda.
  E = DIPOLEPATTERN(THETA,L) où THETA est en radians et L la longueur
  rapportée à la longueur d'onde (0.5 pour un demi-onde).
```

## `directivity`

```
DIRECTIVITY Directivité estimée à partir d'un diagramme en puissance.
```

## `friis`

```
FRIIS Puissance reçue en espace libre (formule de Friis).
```

