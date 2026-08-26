# Toolbox `radar`

```
% Radar Toolbox — équation du radar et traitement d'impulsions.
%
%   radareqrng   - Portée maximale
%   radareqpow   - Puissance nécessaire
%   time2range   - Retard vers distance
%   range2time   - Distance vers retard
%   dopplerShift - Décalage Doppler
%   matchedFilter- Filtre adapté
%   pulseCompression - Compression d'impulsion par corrélation
```

## `dopplerShift`

```
DOPPLERSHIFT Décalage Doppler d'une cible en rapprochement.
```

## `matchedFilter`

```
MATCHEDFILTER Filtre adapté : corrélation avec la réplique retournée.
```

## `pulseCompression`

```
PULSECOMPRESSION Compression d'impulsion et position du maximum.
```

## `radareqpow`

```
RADAREQPOW Puissance d'émission nécessaire pour une portée donnée.
```

## `radareqrng`

```
RADAREQRNG Portée maximale d'un radar, en mètres.
  R = RADAREQRNG(LAMBDA,PT,G,SIGMA,PMIN) applique
  R = ((Pt G^2 lambda^2 sigma) / ((4 pi)^3 Pmin))^(1/4).
```

## `range2time`

```
RANGE2TIME Temps d'aller-retour pour une distance donnée.
```

## `time2range`

```
TIME2RANGE Distance correspondant à un temps d'aller-retour.
```

