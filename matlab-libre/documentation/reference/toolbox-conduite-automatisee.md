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
  OMEGA = PUREPURSUIT(POSE,CHEMIN,DISTANCEVISEE,VITESSE) rend la vitesse
  angulaire à appliquer. POSE vaut [X Y THETA], CHEMIN une liste de
  points en lignes, DISTANCEVISEE la distance à laquelle regarder
  devant, VITESSE la vitesse d'avance — un par défaut.

  [OMEGA,INDICE] = PUREPURSUIT(...) rend aussi l'indice du point visé.

  Le principe tient en une phrase : viser un point du chemin situé à
  DISTANCEVISEE devant soi, et décrire l'arc de cercle qui y mène. Cet
  arc a pour courbure 2 sin(alpha) / L, où alpha est l'angle entre le
  cap et la direction du point visé, d'où

     omega = 2 V sin(alpha) / L

  Le point visé se cherche en avançant depuis le point du chemin le plus
  proche, jamais depuis le début : passé la distance de visée, le début
  du chemin est lui aussi assez loin, et le viser ferait faire demi-tour
  au véhicule.

  DISTANCEVISEE est le seul réglage. Court, le suivi est nerveux et
  oscille ; long, il coupe les virages. Il se choisit en général
  proportionnel à la vitesse.

  Exemple :
     chemin = [linspace(0, 50, 501).', zeros(501, 1)];
     purePursuit([0 1 0], chemin, 5, 5)   % decale a gauche : omega < 0
     purePursuit([0 0 0], chemin, 5, 5)   % sur le chemin : omega = 0

  Voir aussi SMOOTHPATH, LANEOFFSET, BICYCLEMODEL.
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

