# Toolbox `navigation`

```
% Navigation Toolbox — planification et estimation de position.
%
% Planification
%   astar       - Plus court chemin sur une grille d'occupation
%
% Géodésie
%   haversine   - Distance orthodromique entre deux points
%   azimuthTo   - Cap initial d'une orthodromie
%
% Estimation
%   ekfPredict  - Prédiction d'un filtre de Kalman étendu
%   ekfUpdate   - Correction par une mesure
```

## `astar`

```
ASTAR Plus court chemin sur une grille d'occupation (0 libre, 1 occupé).
  [CHEMIN,COUT] = ASTAR(GRILLE,[i j],[i j]) rend la suite des cases
  parcourues, une par ligne, et le coût total. Sans chemin, il rend une
  liste vide et un coût infini — ce qui est un résultat, non une erreur.

  A* est Dijkstra guidé par une estimation de ce qui reste à parcourir.
  L'heuristique employée ici est la distance de Manhattan, qui ne
  surestime jamais le coût restant sur une grille à quatre voisins :
  c'est ce qui garantit que le chemin trouvé est le plus court, et non
  seulement un chemin court.

  Sans obstacle, le coût est exactement la distance de Manhattan entre
  les deux cases : c'est la vérification à faire.

  Exemple :
     grille = zeros(12); grille(4:9, 6) = 1;
     [chemin, cout] = astar(grille, [1 1], [12 12]);
     size(chemin, 1)                 % le nombre de cases

  Voir aussi PUREPURSUIT, BINARYOCCUPANCYMAP.
```

## `azimuthTo`

```
AZIMUTHTO Cap initial, en degrés depuis le nord.
  CAP = AZIMUTHTO(LAT1,LON1,LAT2,LON2) rend le cap à prendre au départ
  pour suivre l'orthodromie, en degrés depuis le nord, dans le sens des
  aiguilles d'une montre.

  C'est le cap *initial* : sur une orthodromie, il change tout au long
  du trajet, sauf le long d'un méridien ou de l'équateur. C'est ce qui
  distingue l'orthodromie de la loxodromie, où le cap est constant mais
  le chemin plus long.

  Aller et revenir ne donne donc pas deux caps opposés à 180 degrés
  près, sauf sur ces deux exceptions.

  Exemple :
     azimuthTo(0, 0, 10, 0)          % 0 : plein nord
     azimuthTo(0, 0, 0, 10)          % 90 : plein est
     azimuthTo(45, 0, 45, 90)        % bien moins que 90 : on passe
                                     % par le nord

  Voir aussi HAVERSINE, RECKON, DISTANCEGC.
```

## `ekfPredict`

```
EKFPREDICT Étape de prédiction d'un filtre de Kalman étendu.
  [X,P] = EKFPREDICT(X,P,F,JACOBIENNE,Q) fait avancer l'estimation d'un
  pas : l'état par la fonction F, sa covariance par la jacobienne.

     X  l'état estimé          P  sa covariance
     F  la fonction d'évolution, une poignée @(x)
     JACOBIENNE  sa dérivée au point courant
     Q  le bruit de modèle

  La prédiction augmente toujours l'incertitude : P croît de Q. C'est
  EKFUPDATE qui la fait décroître, en apportant une mesure.

  L'étendu diffère du linéaire en ce qu'il propage l'état par la vraie
  fonction et la covariance par sa linéarisation. C'est une
  approximation : elle vaut tant que la fonction est presque affine à
  l'échelle de l'incertitude, et se dégrade quand elle ne l'est plus.

  Exemple :
     F = [1 0.1; 0 1];
     [x, P] = ekfPredict(x, P, @(v) F * v, F, diag([1e-3 1e-2]));

  Voir aussi EKFUPDATE, KALMANFILTER.
```

## `ekfUpdate`

```
EKFUPDATE Étape de correction d'un filtre de Kalman étendu.
  [X,P] = EKFUPDATE(X,P,Z,H,JACOBIENNE,R) corrige l'estimation par la
  mesure Z, H étant la fonction de mesure et R son bruit.

  La correction diminue toujours l'incertitude : une mesure, si bruitée
  soit-elle, apporte de l'information. Le régime permanent s'établit
  quand cette diminution équilibre exactement l'augmentation de
  EKFPREDICT.

  Le filtre estime aussi ce qu'aucune mesure ne donne — une vitesse, un
  biais — pourvu que le modèle les relie à ce qu'on mesure. Sur un
  modèle position-vitesse où l'on ne mesure que la position, la vitesse
  s'estime par la façon dont la position évolue, et non directement.
  Son estimation instantanée vagabonde, mais sa moyenne converge.

  Exemple :
     H = [1 0];
     [x, P] = ekfUpdate(x, P, mesure, @(v) H * v, H, 0.5);

  Voir aussi EKFPREDICT, KALMANFILTER.
```

## `haversine`

```
HAVERSINE Distance orthodromique entre deux points, en mètres.
  D = HAVERSINE(LAT1,LON1,LAT2,LON2) rend la distance sur la sphère
  entre deux points donnés en degrés ; HAVERSINE(...,RAYON) impose le
  rayon, celui de la Terre par défaut.

  La formule de l'haversine est préférée à la loi des cosinus
  sphériques parce qu'elle reste précise pour les points proches, là où
  celle-ci perd ses chiffres significatifs en soustrayant deux cosinus
  presque égaux.

  Elle mesure sur une sphère, non sur l'ellipsoïde : l'écart avec la
  géodésique vraie atteint quelques dixièmes de pour cent, ce qui est
  sans importance pour une navigation mais pas pour une géodésie.

  Un degré de latitude vaut environ 111 km, partout ; un degré de
  longitude vaut cela multiplié par le cosinus de la latitude, donc rien
  au pôle.

  Exemple :
     haversine(0, 0, 0, 1)           % environ 111 km, a l'equateur
     haversine(60, 0, 60, 1)         % la moitie, a 60 degres
     haversine(0, 0, 90, 0)          % le quart d'un meridien

  Voir aussi AZIMUTHTO, DISTANCEGC, RECKON.
```

