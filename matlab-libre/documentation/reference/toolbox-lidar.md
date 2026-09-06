# Toolbox `lidar`

```
% Lidar Toolbox — nuages de points télémétriques.
%
% Acquisition
%   pointCloudFromRanges - Du balayage polaire au nuage cartésien
%
% Préparation
%   voxelDownsample      - Un point par cellule, au barycentre
%
% Modèles et recalage
%   fitPlaneRansac       - Droite ou plan dominant, malgré les parasites
%   icpRegister          - Recalage rigide de deux relevés
```

## `fitPlaneRansac`

```
FITPLANERANSAC Droite (2-D) ou plan (3-D) dominant, par RANSAC.
  [MODELE,INLIERS] = FITPLANERANSAC(POINTS,TOLERANCE,ITERATIONS) cherche
  la droite — en deux dimensions — ou le plan — en trois — qui rallie le
  plus de points à moins de TOLERANCE de lui.

  MODELE porte les coefficients de l'équation implicite : [A B C] pour
  A x + B y + C = 0, ou [A B C D] pour A x + B y + C z + D = 0.
  INLIERS donne les indices des points retenus.

  Le principe : tirer au hasard le minimum de points qui détermine un
  modèle — deux pour une droite, trois pour un plan —, compter combien
  de points s'en approchent, et recommencer. Le meilleur tirage gagne.

  C'est ce qui le rend insensible aux points aberrants, là où les
  moindres carrés cèdent : une droite ajustée par moindres carrés sur un
  sol semé de parasites passe entre les deux, alors que RANSAC ignore
  les parasites au lieu de les moyenner.

  TOLERANCE se choisit d'après le bruit de mesure, non d'après la scène.
  Trop serrée, aucun modèle ne rallie assez de points ; trop lâche, tout
  se vaut. ITERATIONS vaut 200 par défaut, ce qui suffit tant que les
  parasites restent minoritaires.

  Exemple :
     sol = [(0:0.1:5).', 0.2 * (0:0.1:5).' + 1];
     nuage = [sol; rand(30, 2) * 5];
     [modele, inliers] = fitPlaneRansac(nuage, 0.05, 500);
     -modele(1) / modele(2)          % la pente, 0.2

  Voir aussi ICPREGISTER, VOXELDOWNSAMPLE, POLYFIT.
```

## `icpRegister`

```
ICPREGISTER Recalage rigide 2-D par ICP.
  [R,T,ERREUR] = ICPREGISTER(SOURCE,CIBLE,ITERATIONS) cherche la
  rotation R et la translation T qui superposent au mieux le nuage
  SOURCE sur le nuage CIBLE. ERREUR est la distance moyenne finale entre
  points appariés.

  L'algorithme alterne deux étapes jusqu'à convergence : apparier chaque
  point de la source à son plus proche voisin dans la cible, puis
  calculer la transformation rigide optimale pour ces appariements — par
  décomposition en valeurs singulières, qui la donne en forme fermée.
  Chaque étape diminue l'erreur, donc l'algorithme converge ; mais rien
  ne garantit qu'il converge vers le bon minimum.

  Il lui faut donc une pose initiale pas trop fausse : ICP part de
  l'identité, et un écart de plus de quelques dizaines de degrés le fait
  tomber dans un minimum local. C'est sa limite connue.

  Il ne peut pas non plus lever une ambiguïté que la géométrie ne
  contient pas : sur un cercle parfait, invariant par rotation, il
  superpose parfaitement les deux nuages en rendant une rotation
  quelconque — parce que la question n'a pas de réponse.

  La transformation rendue est toujours rigide : R'R vaut l'identité et
  son déterminant vaut un, sans symétrie ni changement d'échelle.

  Exemple :
     forme = [cos(0:0.1:2*pi).', sin(0:0.1:2*pi).'] .* [2 1];
     a = deg2rad(12);
     Rv = [cos(a) -sin(a); sin(a) cos(a)];
     [R, t] = icpRegister(forme, (Rv * forme.').' + [0.4 -0.25], 60);
     rad2deg(atan2(R(2,1), R(1,1)))  % 12

  Voir aussi FITPLANERANSAC, VOXELDOWNSAMPLE, POINTCLOUDFROMRANGES.
```

## `pointCloudFromRanges`

```
POINTCLOUDFROMRANGES Nuage cartésien à partir d'un balayage polaire.
  P = POINTCLOUDFROMRANGES(DISTANCES,ANGLES) rend un nuage à deux
  colonnes, X et Y, à partir des distances mesurées et de l'angle de
  chaque rayon, en radians.

  Un télémètre ne rend que des distances : c'est en cartésien que la
  géométrie redevient lisible. Un mur droit, par exemple, donne des
  distances qui croissent en 1/cos(theta) — rien n'y ressemble à une
  droite tant qu'on n'a pas converti.

  La conversion est un simple changement de coordonnées : elle conserve
  les distances à l'origine, et n'invente rien.

  Exemple :
     angles = deg2rad(-40:0.5:40);
     points = pointCloudFromRanges(2 ./ cos(angles), angles);
     max(abs(points(:,1) - 2))       % 0 : un mur droit a 2 m

  Voir aussi VOXELDOWNSAMPLE, FITPLANERANSAC, ICPREGISTER.
```

## `voxelDownsample`

```
VOXELDOWNSAMPLE Un point par cellule de la grille, au barycentre.
  R = VOXELDOWNSAMPLE(POINTS,TAILLE) découpe l'espace en cellules
  cubiques de côté TAILLE et ne garde qu'un point par cellule occupée,
  placé au barycentre de ceux qu'elle contenait.

  Un télémètre produit bien plus de points qu'il n'en faut, et surtout
  les produit inégalement : très dense près du capteur, clairsemé loin.
  Le sous-échantillonnage par voxels égalise cette densité, ce qui
  change tout pour les méthodes qui la supposent uniforme — ICP en
  premier lieu, qui sans cela tire vers les zones denses.

  Prendre le barycentre plutôt qu'un point au hasard réduit aussi le
  bruit de mesure, d'un facteur racine du nombre de points de la
  cellule.

  TAILLE est le seul réglage : plus grosse, moins de points, et moins de
  détail. Deux points d'une même cellule ne peuvent pas survivre tous
  les deux — c'est la garantie de la méthode.

  Exemple :
     nuage = randn(1000, 2) * 0.3;
     size(voxelDownsample(nuage, 0.25), 1)   % bien moins de 1000

  Voir aussi POINTCLOUDFROMRANGES, FITPLANERANSAC.
```

