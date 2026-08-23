# Toolbox `vision`

```
% Computer Vision Toolbox — vision par ordinateur.
%
%   detectHarrisFeatures - Points d'intérêt de Harris
%   detectFASTFeatures   - Coins FAST
%   extractFeatures      - Descripteurs de voisinage
%   matchFeatures        - Appariement de descripteurs
%   estimateGeometricTransform - Transformation affine par moindres carrés
%   insertShape          - Dessin de formes dans une image
%   integralImage        - Image intégrale
%   houghLines           - Détection de droites par transformée de Hough
%   opticalFlowLK        - Flot optique de Lucas-Kanade
%   bboxOverlapRatio     - Recouvrement de boîtes englobantes
%
% Boîtes englobantes
%   bbox2points             - Coins d'une boîte
%   bboxresize              - Redimensionnement
%   bboxOverlapRatioMatrix  - Recouvrement de toutes les paires
%   selectStrongestBbox     - Suppression des non-maxima
%   selectStrongest         - Les N points les mieux notés
%
% Affichage
%   insertMarker            - Marqueurs sur une image
```

## `bbox2points`

```
BBOX2POINTS Coins d'une boîte englobante.
  P = BBOX2POINTS([X Y L H]) rend les quatre coins, dans le sens
  horaire depuis le coin haut-gauche : une matrice 4x2.

  Exemple :
     bbox2points([1 2 10 20])   % [1 2; 11 2; 11 22; 1 22]
```

## `bboxOverlapRatio`

```
BBOXOVERLAPRATIO Recouvrement de boîtes englobantes (intersection/union).
  Les boîtes s'écrivent [x y largeur hauteur].
```

## `bboxOverlapRatioMatrix`

```
BBOXOVERLAPRATIOMATRIX Recouvrement de toutes les paires de boîtes.
  R(i,j) est le rapport de l'intersection sur l'union entre A(i,:) et
  B(j,:). C'est la forme matricielle de BBOXOVERLAPRATIO.
```

## `bboxresize`

```
BBOXRESIZE Redimensionne des boîtes englobantes.
  B = BBOXRESIZE(BBOX,ECHELLE) où ECHELLE est un facteur ou un couple
  [vertical horizontal], comme dans MATLAB.

  Exemple :
     bboxresize([1 1 10 20], 2)   % [2 2 20 40]
```

## `detectFASTFeatures`

```
DETECTFASTFEATURES Coins FAST (cercle de Bresenham de rayon 3).
  P = DETECTFASTFEATURES(I,SEUIL) rend les coordonnées [x y] des points
  dont au moins neuf voisins consécutifs du cercle sont tous plus clairs
  ou tous plus sombres que le centre, à SEUIL près.
```

## `detectHarrisFeatures`

```
DETECTHARRISFEATURES Points d'intérêt par le détecteur de Harris.
  [P,R] = DETECTHARRISFEATURES(I) rend les coordonnées [x y] des coins et
  leur réponse. Option 'MinQuality' (0.01 par défaut).
```

## `estimateGeometricTransform`

```
ESTIMATEGEOMETRICTRANSFORM Transformation entre deux jeux de points.
  T = ESTIMATEGEOMETRICTRANSFORM(P1,P2,'affine') rend la matrice 3x3 qui
  envoie P1 sur P2 au sens des moindres carrés.
```

## `extractFeatures`

```
EXTRACTFEATURES Descripteurs par imagette normalisée autour de chaque point.
  [D,P] = EXTRACTFEATURES(I,POSITIONS) rend une ligne de descripteur par
  point retenu : le voisinage centré, centré-réduit puis mis à plat.
```

## `houghLines`

```
HOUGHLINES Détection de droites par transformée de Hough.
  [D,A] = HOUGHLINES(BW,N) rend les N droites les plus votées, sous
  forme de couples [rho theta] (theta en degrés).
```

## `insertMarker`

```
INSERTMARKER Dessine des marqueurs sur une image.
  SORTIE = INSERTMARKER(I,POSITIONS,FORME) où FORME vaut 'circle',
  'x', 'plus' ou 'square'. POSITIONS est une matrice Nx2 de [x y].
  Options : 'Color' et 'Size'.
```

## `insertShape`

```
INSERTSHAPE Dessine un rectangle ou une ligne dans une image.
  J = INSERTSHAPE(I,'rectangle',[x y w h]) trace le contour.
  J = INSERTSHAPE(I,'line',[x1 y1 x2 y2]) trace un segment.
```

## `integralImage`

```
INTEGRALIMAGE Image intégrale (sommes cumulées en deux dimensions).
  J(i+1,j+1) est la somme des pixels du rectangle allant du coin
  supérieur gauche à (i,j).
```

## `matchFeatures`

```
MATCHFEATURES Appariement de descripteurs par plus proche voisin.
  PAIRES = MATCHFEATURES(D1,D2) rend les couples d'indices appariés. Le
  test du rapport des deux meilleures distances (0.7) élimine les
  appariements ambigus.
```

## `opticalFlowLK`

```
OPTICALFLOWLK Flot optique par la méthode de Lucas-Kanade.
  [U,V] = OPTICALFLOWLK(I1,I2) rend les deux composantes du déplacement
  estimé en chaque pixel.
```

## `selectStrongest`

```
SELECTSTRONGEST Garde les N points les plus forts.
  [P,IDX] = SELECTSTRONGEST(POINTS,METRIQUE,N) trie par métrique
  décroissante et garde les N premiers.
```

## `selectStrongestBbox`

```
SELECTSTRONGESTBBOX Suppression des non-maxima sur des boîtes.
  [B,S] = SELECTSTRONGESTBBOX(BOITES,SCORES,SEUIL) garde la boîte la
  mieux notée, écarte celles qui la recouvrent de plus de SEUIL, et
  recommence. SEUIL vaut 0,5 par défaut.

  Exemple :
     b = [1 1 10 10; 2 2 10 10; 50 50 10 10];
     size(selectStrongestBbox(b, [0.9; 0.8; 0.7]), 1)   % 2
```

