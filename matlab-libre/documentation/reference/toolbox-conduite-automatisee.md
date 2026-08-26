# Toolbox `conduite-automatisee`

```
% Automated Driving Toolbox — aide à la conduite.
%
%   timeToCollision - Temps avant collision
%   purePursuit     - Loi de poursuite pure
%   smoothPath      - Lissage d'une trajectoire
%   laneOffset      - Écart latéral à la voie
```

## `laneOffset`

```
LANEOFFSET Écart latéral au centre de la voie.
```

## `purePursuit`

```
PUREPURSUIT Loi de poursuite pure pour suivre un chemin.
  POSE vaut [x y theta]. Rend la vitesse angulaire à appliquer.
```

## `smoothPath`

```
SMOOTHPATH Lissage d'une trajectoire par descente de gradient.
```

## `timeToCollision`

```
TIMETOCOLLISION Temps avant collision, en secondes.
  Rend l'infini si la vitesse relative n'est pas un rapprochement.
```

