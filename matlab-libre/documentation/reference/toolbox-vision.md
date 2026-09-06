# Toolbox `vision`

```
% Computer Vision Toolbox — vision par ordinateur.
%
% Points d'intérêt et descripteurs
%   detectHarrisFeatures   - Coins de Harris
%   detectMinEigenFeatures - Coins de Shi et Tomasi
%   detectFASTFeatures     - Coins FAST
%   detectBRISKFeatures    - Coins FAST retenus dans l'espace des échelles
%   detectORBFeatures      - Coins FAST orientés, sur une pyramide
%   detectSURFFeatures     - Taches, par la Hessienne approchée
%   extractFeatures        - Descripteurs de voisinage
%   extractHOGFeatures     - Histogrammes de gradients orientés
%   extractLBPFeatures     - Motifs binaires locaux
%   matchFeatures          - Appariement de descripteurs
%   selectStrongest        - Les N points les mieux notés
%   selectUniform          - Points répartis sur toute l'image
%
% Images intégrales
%   integralImage          - Table de sommes cumulées
%   integralFilter         - Filtrage par boîtes pondérées
%
% Géométrie
%   estimateGeometricTransform   - Transformation affine par moindres carrés
%   estimateGeometricTransform2D - Similitude, affine ou projective
%   estimateFundamentalMatrix    - Matrice fondamentale, huit points ou MSAC
%   estimateUncalibratedRectification - Rectification sans calibrage
%   epipolarLine                 - Droites épipolaires
%   triangulate                  - Reconstruction par intersection de rayons
%   rotationVectorToMatrix       - Formule de Rodrigues
%   rotationMatrixToVector       - Axe et angle d'une rotation
%   generateCheckerboardPoints   - Coins d'un damier d'étalonnage
%   houghLines                   - Droites par transformée de Hough
%
% Caméra
%   cameraIntrinsics        - Paramètres internes d'une caméra
%   cameraParameters        - Paramètres internes et distorsion
%   cameraMatrix            - Matrice de projection complète
%   worldToImage            - Projection de points du monde
%   pointsToWorld           - Relèvement sur le plan z égal zéro
%   undistortPoints         - Correction de la distorsion
%
% Stéréo et mouvement
%   stereoAnaglyph          - Anaglyphe rouge-cyan
%   disparityBM             - Disparité par appariement de blocs
%   disparitySGM            - Disparité par appariement semi-global
%   rectifyStereoImages     - Redressement d'une paire stéréo
%   reconstructScene        - Nuage de points à partir d'une disparité
%   opticalFlowLK           - Flot optique de Lucas et Kanade
%   opticalFlowHS           - Flot optique de Horn et Schunck
%   opticalFlowFarneback    - Flot optique par expansion polynomiale
%   assignDetectionsToTracks - Appariement optimal, algorithme hongrois
%
% Nuages de points
%   pointCloud              - Nuage de points, organisé ou non
%   pctransform             - Transformation rigide d'un nuage
%   pcdownsample            - Allègement au hasard ou par grille
%   pcdenoise               - Retrait des points isolés
%   pcmerge                 - Fusion de deux nuages
%   pcnormals               - Normales par plan tangent local
%   pcfitplane              - Plan dominant, par tirages aléatoires
%   pcsegdist               - Groupes de points connexes
%   pcregistericp           - Recalage par points les plus proches
%
% Régions
%   superpixels             - Découpage en régions homogènes
%   labeloverlay            - Superposition d'un étiquetage
%
% Boîtes englobantes
%   bbox2points             - Coins d'une boîte
%   bboxresize              - Redimensionnement
%   bboxOverlapRatio        - Recouvrement de deux boîtes
%   bboxOverlapRatioMatrix  - Recouvrement de toutes les paires
%   bboxPrecisionRecall     - Précision et rappel d'une détection
%   selectStrongestBbox     - Suppression des non-maxima
%
% Affichage
%   insertShape             - Dessin de formes dans une image
%   insertMarker            - Marqueurs sur une image
%   insertText              - Texte dans une image
%   insertObjectAnnotation  - Objets entourés et nommés
```

## `assignDetectionsToTracks`

_Pas de bloc d'aide._

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

## `bboxPrecisionRecall`

```
BBOXPRECISIONRECALL Précision et rappel d'une détection de boîtes.
  [P,R] = BBOXPRECISIONRECALL(D,V) compare les boîtes détectées aux
  boîtes de vérité terrain. Une détection compte comme juste si son
  recouvrement avec une boîte de vérité dépasse le seuil, et si cette
  boîte n'a pas déjà été prise : une même vérité ne peut pas justifier
  deux détections.

  [P,R] = BBOXPRECISIONRECALL(D,V,SEUIL) fixe le seuil de recouvrement,
  0.5 par défaut, valeur retenue par les concours de détection.

  La précision est la part des détections qui sont justes, le rappel la
  part des vérités qui ont été trouvées. Les deux se lisent ensemble :
  détecter tout donne un rappel parfait et une précision nulle.

  Exemple :
     [p, r] = bboxPrecisionRecall([10 10 20 20], [10 10 20 20]);
     % p = 1, r = 1

  Voir aussi BBOXOVERLAPRATIO, SELECTSTRONGESTBBOX.
```

## `bboxresize`

```
BBOXRESIZE Redimensionne des boîtes englobantes.
  B = BBOXRESIZE(BBOX,ECHELLE) où ECHELLE est un facteur ou un couple
  [vertical horizontal], comme dans MATLAB.

  Exemple :
     bboxresize([1 1 10 20], 2)   % [2 2 20 40]
```

## `cameraIntrinsics`

```
CAMERAINTRINSICS Paramètres internes d'une caméra.
  C = CAMERAINTRINSICS([FX FY],[CX CY],[H L]) décrit la géométrie d'une
  caméra : distances focales en pixels, point principal, taille de
  l'image.

  La matrice rendue suit la convention de MATLAB, transposée de la
  convention usuelle : le point est un vecteur ligne et la matrice le
  multiplie à droite. C'est la même géométrie, écrite dans l'autre sens.

  CAMERAINTRINSICS(...,'RadialDistortion',K,'TangentialDistortion',P,
  'Skew',S) ajoute la distorsion de l'objectif et l'obliquité des
  pixels.

  Exemple :
     c = cameraIntrinsics([800 800], [320 240], [480 640]);
     c.K

  Voir aussi CAMERAPARAMETERS, CAMERAMATRIX, WORLDTOIMAGE, POINTSTOWORLD.
```

## `cameraMatrix`

```
CAMERAMATRIX Matrice de projection d'une caméra posée dans le monde.
  P = CAMERAMATRIX(PARAMS,R,T) rend la matrice 4x3 qui projette un point
  du monde, écrit en coordonnées homogènes et en ligne, sur le plan
  image : [x y w] = [X Y Z 1] * P, et le point image est [x/w y/w].

  La matrice réunit la pose — où est la caméra — et la géométrie
  interne — comment elle voit. Séparer les deux est ce qui permet
  d'étalonner une fois et de bouger ensuite.

  Exemple :
     c = cameraIntrinsics([800 800], [320 240], [480 640]);
     P = cameraMatrix(c, eye(3), [0 0 10]);

  Voir aussi CAMERAINTRINSICS, WORLDTOIMAGE, TRIANGULATE.
```

## `cameraParameters`

```
CAMERAPARAMETERS Paramètres complets d'une caméra, internes et externes.
  C = CAMERAPARAMETERS('IntrinsicMatrix',K,'RadialDistortion',R,...)
  réunit ce qui décrit une caméra : sa géométrie interne, la distorsion
  de son objectif, et éventuellement la pose qu'elle avait pour chaque
  image d'étalonnage.

  Les propriétés : IntrinsicMatrix, FocalLength, PrincipalPoint, Skew,
  RadialDistortion, TangentialDistortion, RotationMatrices,
  TranslationVectors, ImageSize.

  Exemple :
     c = cameraParameters('IntrinsicMatrix', [800 0 0; 0 800 0; 320 240 1]);

  Voir aussi CAMERAINTRINSICS, CAMERAMATRIX, UNDISTORTPOINTS.
```

## `detectBRISKFeatures`

```
DETECTBRISKFEATURES Coins FAST retenus dans l'espace des échelles.
  P = DETECTBRISKFEATURES(I) rend les coordonnées [x y] des coins, dans
  les coordonnées de l'image de départ.

  [P,METRIQUE,ECHELLE] = DETECTBRISKFEATURES(I) rend aussi le score de
  chaque coin — le plus grand seuil auquel il reste un coin — et
  l'échelle où il est le plus marqué.

  La pyramide comporte, entre deux octaves, une couche intermédiaire à
  une fois et demie l'échelle : les échelles sont donc 1, 1,5, 2, 3, 4,
  6, et ainsi de suite. Un coin n'est retenu que s'il domine ses voisins
  dans sa couche et dans les deux couches encadrantes — c'est cette
  comparaison qui lui attribue une échelle propre, là où FAST seul en
  rendrait un par couche. Sa position est ensuite affinée au sous-pixel
  par une parabole, ce qui lui rend la précision que la réduction de
  l'image lui avait ôtée.

  Options et valeurs par défaut :
    'MinContrast'  0.2, l'écart d'intensité minimal, sur 0-1
    'MinQuality'   0.1, la part du score le plus fort en deçà de
                   laquelle un coin est écarté
    'NumOctaves'   4
    'ROI'          [x y largeur hauteur]

  Exemple :
     I = zeros(90); I(25:60, 25:60) = 1;
     [p, m, e] = detectBRISKFeatures(I);
     size(p, 1)      % les quatre coins du carré

  Voir aussi DETECTORBFEATURES, DETECTSURFFEATURES, DETECTFASTFEATURES.
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

## `detectMinEigenFeatures`

```
DETECTMINEIGENFEATURES Coins de Shi et Tomasi.
  [P,R] = DETECTMINEIGENFEATURES(I) rend les coordonnées [x y] des coins
  et leur réponse. Le critère est la plus petite valeur propre de la
  matrice d'autocorrélation locale

     M = [ Sxx Sxy ; Sxy Syy ]

  qui vaut ((Sxx+Syy) - sqrt((Sxx-Syy)^2 + 4 Sxy^2)) / 2. Un coin est un
  point où les deux valeurs propres sont grandes : prendre la plus
  petite est plus direct que la combinaison de Harris, et c'est ce
  critère qui décide des points à suivre dans un flot optique.

  Options : 'MinQuality' (0.01), 'FilterSize' (5).

  Exemple :
     I = zeros(20); I(6:15, 6:15) = 1;
     p = detectMinEigenFeatures(I);   % les quatre coins du carré

  Voir aussi DETECTHARRISFEATURES, DETECTFASTFEATURES, SELECTSTRONGEST.
```

## `detectORBFeatures`

```
DETECTORBFEATURES Coins FAST orientés, à plusieurs échelles.
  P = DETECTORBFEATURES(I) rend les coordonnées [x y] des coins trouvés
  sur une pyramide d'images réduites, ramenées aux coordonnées de
  l'image de départ.

  [P,METRIQUE,ORIENTATION,ECHELLE] = DETECTORBFEATURES(I) rend aussi la
  réponse de Harris de chaque coin, son orientation en radians, et
  l'échelle du niveau où il a été trouvé.

  Le détecteur est celui de FAST, appliqué à chaque niveau d'une
  pyramide : c'est ce qui lui donne l'invariance d'échelle que FAST seul
  n'a pas. Les coins sont ensuite classés par la réponse de Harris,
  meilleure que le score de FAST pour écarter les points de contour.
  L'orientation est celle du vecteur qui va du coin au centre de masse
  des intensités de son voisinage : elle tourne avec l'image, ce qui
  rend le point comparable d'une vue à l'autre.

  Options et valeurs par défaut :
    'ScaleFactor'  1.2, le rapport d'un niveau au suivant
    'NumLevels'    8
    'MinContrast'  0.08, l'écart d'intensité minimal, sur 0-1
    'ROI'          [x y largeur hauteur]

  Exemple :
     I = zeros(80); I(20:50, 20:50) = 1;
     [p, m, o] = detectORBFeatures(I);
     size(p, 1) >= 4      % les quatre coins du carré

  Voir aussi DETECTBRISKFEATURES, DETECTSURFFEATURES, DETECTFASTFEATURES,
  DETECTHARRISFEATURES.
```

## `detectSURFFeatures`

```
DETECTSURFFEATURES Points d'intérêt par la Hessienne approchée.
  P = DETECTSURFFEATURES(I) rend les coordonnées [x y] des taches
  claires ou sombres de l'image, à toutes les tailles.

  [P,METRIQUE,ECHELLE,SIGNE] = DETECTSURFFEATURES(I) rend aussi la force
  de chaque point, l'échelle à laquelle il a été trouvé, et le signe de
  la trace de la Hessienne — positif pour une tache sombre sur fond
  clair, négatif pour l'inverse. Ce signe permet d'écarter d'emblée deux
  points qui ne peuvent pas se correspondre.

  Le détecteur cherche les maxima du déterminant de la matrice
  hessienne, dans l'espace formé du plan de l'image et de l'échelle. Les
  dérivées secondes sont approchées par des filtres à boîte, calculés en
  temps fixe depuis l'image intégrale : c'est ce qui permet d'agrandir
  le filtre plutôt que de réduire l'image, et donc de balayer les
  échelles sans rééchantillonner.

  Options et valeurs par défaut :
    'MetricThreshold'  1000, sur une image ramenée à l'intervalle 0-255
    'NumOctaves'       3
    'NumScaleLevels'   4
    'ROI'              [x y largeur hauteur], la zone à examiner

  Exemple :
     I = zeros(120); I(40:60, 40:60) = 1;
     I = imfilter(I, fspecial('gaussian', 21, 4), 'replicate');
     [p, m, e] = detectSURFFeatures(I);
     p(1, :)      % le centre de la tache

  Voir aussi DETECTBRISKFEATURES, DETECTORBFEATURES, EXTRACTFEATURES,
  DETECTHARRISFEATURES.
```

## `disparityBM`

```
DISPARITYBM Carte de disparité par appariement de blocs.
  D = DISPARITYBM(G,D) rend, pour chaque pixel de l'image gauche, le
  décalage horizontal qui rend son voisinage le plus semblable dans
  l'image droite. La mesure de ressemblance est la somme des différences
  absolues, calculée sur un bloc carré.

  Les deux images sont supposées rectifiées : le correspondant d'un
  pixel est sur la même ligne, ce qui ramène la recherche à une
  dimension. La disparité est inversement proportionnelle à la
  profondeur.

  Options et valeurs par défaut :
    'DisparityRange'  [0 16], à valeurs entières
    'BlockSize'       15, impair

  [D,C] = DISPARITYBM(...) rend aussi le coût du meilleur appariement,
  qui sert à repérer les zones sans texture où la mesure ne veut rien
  dire.

  Exemple :
     g = zeros(20, 40); g(:, 10:15) = 1;
     d = zeros(20, 40); d(:, 7:12) = 1;
     carte = disparityBM(g, d, 'BlockSize', 5, 'DisparityRange', [0 8]);
     round(median(carte(:, 10:15)(:)))   % 3

  Voir aussi STEREOANAGLYPH.
```

## `disparitySGM`

```
DISPARITYSGM Carte de disparité par appariement semi-global.
  D = DISPARITYSGM(G,D) rend, pour chaque pixel de l'image gauche, le
  décalage horizontal qui l'apparie dans l'image droite. Les deux images
  sont supposées rectifiées.

  L'appariement bloc à bloc décide de chaque pixel isolément, ce qui le
  rend bruyant dans les zones sans texture. L'appariement semi-global
  ajoute un coût au changement de disparité entre voisins et propage ce
  coût le long de plusieurs directions de balayage : chaque pixel est
  alors décidé en tenant compte de toute une ligne, sans qu'il faille
  pour autant optimiser l'image entière d'un coup.

  La ressemblance est mesurée par la transformée de recensement, qui ne
  retient que l'ordre des intensités : deux prises de vue d'éclairage
  différent restent comparables.

  Options et valeurs par défaut :
    'DisparityRange'        [0 64], à valeurs entières et de largeur
                            multiple de 16 dans MATLAB
    'UniquenessThreshold'   15 ; un pixel dont le second meilleur coût
                            n'est pas plus grand d'au moins ce
                            pourcentage est déclaré non apparié (NaN)

  La carte rendue est en simple précision ; elle est raffinée au
  sous-pixel par ajustement d'une parabole sur les trois coûts autour du
  minimum.

  Exemple :
     rng(1);
     motif = imfilter(rand(40, 100), fspecial('gaussian', 7, 1.5), 'replicate');
     g = motif(:, 11:80);
     d = motif(:, 14:83);       % la même scène, vue trois colonnes plus loin
     carte = disparitySGM(g, d, 'DisparityRange', [0 16]);
     median(median(carte(10:30, 25:60)))      % 3

  Voir aussi DISPARITYBM, RECTIFYSTEREOIMAGES, RECONSTRUCTSCENE.
```

## `epipolarLine`

```
EPIPOLARLINE Droites épipolaires associées à des points.
  L = EPIPOLARLINE(F,P) rend, pour chaque point de la première image, la
  droite de la seconde sur laquelle son correspondant doit se trouver.
  Chaque ligne de L porte [A B C] pour A*x + B*y + C = 0.

  C'est la contrainte épipolaire : connaître F réduit la recherche d'un
  appariement de deux dimensions à une seule.

  L = EPIPOLARLINE(F',P) rend les droites de la première image
  correspondant à des points de la seconde.

  Exemple :
     l = epipolarLine(F, p1);
     abs(sum(l .* [p2 ones(n,1)], 2))   % nul si p2 correspond à p1

  Voir aussi ESTIMATEFUNDAMENTALMATRIX, TRIANGULATE.
```

## `estimateFundamentalMatrix`

```
ESTIMATEFUNDAMENTALMATRIX Matrice fondamentale d'une paire d'images.
  F = ESTIMATEFUNDAMENTALMATRIX(P1,P2) rend la matrice qui lie deux vues
  d'une même scène : pour tout couple de points correspondants,

     [x2 y2 1] * F * [x1 y1 1]' = 0

  F est de rang deux, ce qui est imposé explicitement : la troisième
  valeur singulière est mise à zéro. Sans cela, les droites épipolaires
  ne concourraient pas.

  L'algorithme est celui des huit points normalisé de Hartley : les
  points sont d'abord centrés et mis à l'échelle pour que leur distance
  moyenne à l'origine vaille racine de deux. Sans cette normalisation,
  le système est mal conditionné et le résultat sans valeur.

  [F,VALIDES,STATUT] = ESTIMATEFUNDAMENTALMATRIX(...,'Method',M) où M
  vaut 'Norm8Point' (défaut), 'RANSAC' ou 'MSAC' ; les deux derniers
  écartent les appariements aberrants et rendent leur masque. Options
  'DistanceThreshold' (0.01) et 'NumTrials' (500). Le seuil est une
  distance symétrique aux droites épipolaires, en pixels : à la
  différence de l'erreur de Sampson, elle ne dépend pas de l'échelle
  choisie pour F.

  Exemple :
     F = estimateFundamentalMatrix(p1, p2);
     max(abs(sum(([p2 ones(n,1)] * F) .* [p1 ones(n,1)], 2)))   % petit

  Voir aussi EPIPOLARLINE, TRIANGULATE, ESTIMATEGEOMETRICTRANSFORM.
```

## `estimateGeometricTransform`

```
ESTIMATEGEOMETRICTRANSFORM Transformation entre deux jeux de points.
  T = ESTIMATEGEOMETRICTRANSFORM(P1,P2,'affine') rend la matrice 3x3 qui
  envoie P1 sur P2 au sens des moindres carrés.
```

## `estimateGeometricTransform2D`

```
ESTIMATEGEOMETRICTRANSFORM2D Transformation géométrique entre deux jeux
  de points.
  T = ESTIMATEGEOMETRICTRANSFORM2D(P1,P2,TYPE) rend la matrice 3x3 qui
  envoie P1 sur P2. TYPE vaut 'similarity', 'affine' ou 'projective'.

  La convention est celle de MATLAB : les points sont des lignes, et la
  transformation s'applique à droite, [x y 1] * T.

  [T,VALIDES] = ESTIMATEGEOMETRICTRANSFORM2D(...,'MaxDistance',D) écarte
  les appariements dont l'erreur de reprojection dépasse D, par tirages
  aléatoires, et rend leur masque.

  Exemple :
     p1 = [0 0; 1 0; 0 1; 2 2];
     p2 = p1 * 2 + 3;
     T = estimateGeometricTransform2D(p1, p2, 'similarity');

  Voir aussi ESTIMATEGEOMETRICTRANSFORM, ESTIMATEFUNDAMENTALMATRIX.
```

## `estimateUncalibratedRectification`

```
ESTIMATEUNCALIBRATEDRECTIFICATION Rectifie une paire d'images sans calibrage.
  [T1,T2] = ESTIMATEUNCALIBRATEDRECTIFICATION(F,P1,P2,TAILLE) rend deux
  transformations projectives qui, appliquées aux deux images, rendent
  les droites épipolaires horizontales : deux points correspondants se
  retrouvent alors sur la même ligne, et la recherche de disparité se
  ramène à une dimension.

  F est la matrice fondamentale telle que la rend
  ESTIMATEFUNDAMENTALMATRIX, P1 et P2 les points appariés, TAILLE la
  taille [lignes colonnes] des images. Les matrices rendues sont dans la
  convention de MATLAB : un point s'écrit en ligne, [x y 1] * T.

  La construction est celle de Hartley. Pour la seconde image, on envoie
  son épipôle à l'infini : une translation amène le centre de l'image à
  l'origine, une rotation pose l'épipôle sur l'axe des x, et une
  dernière matrice l'y repousse à l'infini. Pour la première image, on
  compose d'abord la transformation qui la met en correspondance avec la
  seconde, puis on cherche l'affinité horizontale qui rapproche au mieux
  les points appariés — ce qui minimise la disparité résiduelle sans
  toucher aux lignes, donc sans défaire la rectification.

  Une même translation est appliquée aux deux images pour ramener leurs
  coins dans le quadrant positif ; elle est commune aux deux, donc elle
  ne rompt pas l'alignement des lignes.

  Exemple :
     F = estimateFundamentalMatrix(p1, p2);
     [T1, T2] = estimateUncalibratedRectification(F, p1, p2, size(I1));
     [J1, J2] = rectifyStereoImages(I1, I2, T1, T2);

  Voir aussi ESTIMATEFUNDAMENTALMATRIX, RECTIFYSTEREOIMAGES, EPIPOLARLINE.
```

## `extractFeatures`

```
EXTRACTFEATURES Descripteurs par imagette normalisée autour de chaque point.
  [D,P] = EXTRACTFEATURES(I,POSITIONS) rend une ligne de descripteur par
  point retenu : le voisinage centré, centré-réduit puis mis à plat.
```

## `extractHOGFeatures`

```
EXTRACTHOGFEATURES Histogrammes de gradients orientés.
  F = EXTRACTHOGFEATURES(I) rend le descripteur de Dalal et Triggs : le
  gradient est calculé partout, son orientation votée dans des
  histogrammes par cellule, puis les cellules groupées en blocs
  normalisés qui se recouvrent.

  Le recouvrement des blocs est ce qui donne au descripteur sa
  robustesse : chaque cellule est normalisée plusieurs fois, avec des
  voisinages différents, si bien qu'un changement local d'éclairage
  n'emporte pas tout.

  Options et valeurs par défaut :
    'CellSize'      [8 8]
    'BlockSize'     [2 2]      en cellules
    'BlockOverlap'  [1 1]      moitié du bloc
    'NumBins'       9
    'UseSignedOrientation'  false, l'orientation est prise modulo pi

  La longueur du descripteur vaut
    prod(BlocsParImage) * prod(BlockSize) * NumBins
  avec
    BlocsParImage = floor((floor(taille./CellSize) - BlockSize) ./
                          (BlockSize - BlockOverlap)) + 1

  [F,INFO] = EXTRACTHOGFEATURES(...) rend aussi cette disposition.

  Exemple :
     f = extractHOGFeatures(zeros(64, 64));
     numel(f)   % 1764 = 7*7 blocs * 4 cellules * 9 secteurs

  Voir aussi EXTRACTLBPFEATURES, EXTRACTFEATURES.
```

## `extractLBPFeatures`

```
EXTRACTLBPFEATURES Motifs binaires locaux.
  F = EXTRACTLBPFEATURES(I) compare chaque pixel à ses voisins sur un
  cercle : le motif binaire obtenu décrit la texture locale, et
  l'histogramme de ces motifs décrit la texture de l'image.

  Le motif ne dépend que de l'ordre des intensités, pas de leur valeur :
  le descripteur est donc insensible à tout changement monotone
  d'éclairage, ce qui est sa raison d'être.

  Options et valeurs par défaut :
    'NumNeighbors'  8
    'Radius'        1
    'Upright'       true   sinon le motif est ramené à sa rotation
                           minimale, ce qui le rend invariant par
                           rotation
    'CellSize'      la taille de l'image, soit un seul histogramme
    'Normalization' 'L2', ou 'None'

  La longueur du descripteur vaut le nombre de cellules multiplié par
  P*(P-1)+3 si Upright, par P+2 sinon : seuls les motifs uniformes,
  ceux qui ont au plus deux transitions, reçoivent leur propre case.

  Exemple :
     f = extractLBPFeatures(rand(32));
     numel(f)   % 59

  Voir aussi EXTRACTHOGFEATURES, EXTRACTFEATURES.
```

## `generateCheckerboardPoints`

```
GENERATECHECKERBOARDPOINTS Coins théoriques d'un damier d'étalonnage.
  P = GENERATECHECKERBOARDPOINTS([M N],T) rend les coordonnées des coins
  intérieurs d'un damier de M par N carrés dont le côté mesure T. Il y
  en a (M-1)*(N-1), rangés colonne par colonne, la première à l'origine.

  Ce sont les points de référence auxquels comparer ceux détectés dans
  une photographie du damier, pour en déduire les paramètres de la
  caméra.

  Exemple :
     p = generateCheckerboardPoints([3 4], 10);
     size(p)   % [6 2] : deux lignes de trois coins

  Voir aussi ESTIMATEGEOMETRICTRANSFORM.
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

## `insertObjectAnnotation`

```
INSERTOBJECTANNOTATION Entoure des objets et les nomme.
  J = INSERTOBJECTANNOTATION(I,'rectangle',POSITION,ETIQUETTE) trace un
  rectangle [x y largeur hauteur] par ligne de POSITION et écrit
  l'étiquette correspondante au-dessus.

  J = INSERTOBJECTANNOTATION(I,'circle',POSITION,ETIQUETTE) fait de même
  avec des cercles [x y rayon].

  ETIQUETTE est une chaîne, un tableau de cellules, ou un vecteur de
  nombres — un score de détection, par exemple.

  Options et valeurs par défaut :
    'Color'           'yellow', une couleur ou une par objet
    'TextColor'       'black'
    'TextBoxOpacity'  0.6
    'FontSize'        12
    'LineWidth'       1

  L'image rendue est en couleurs, dans la classe de l'image d'entrée.

  Exemple :
     I = zeros(80, 120);
     J = insertObjectAnnotation(I, 'rectangle', [20 30 40 25], 'chat');
     size(J)     % 80 120 3

  Voir aussi INSERTTEXT, INSERTSHAPE, INSERTMARKER, BBOX2POINTS.
```

## `insertShape`

```
INSERTSHAPE Dessine un rectangle ou une ligne dans une image.
  J = INSERTSHAPE(I,'rectangle',[x y w h]) trace le contour.
  J = INSERTSHAPE(I,'line',[x1 y1 x2 y2]) trace un segment.
```

## `insertText`

```
INSERTTEXT Écrit du texte dans une image.
  J = INSERTTEXT(I,POSITION,TEXTE) dessine TEXTE dans l'image I, sur un
  cartouche opaque, au point POSITION donné en [x y]. POSITION peut
  avoir plusieurs lignes ; TEXTE est alors un tableau de cellules de la
  même longueur, ou une seule chaîne répétée, ou un vecteur de nombres.

  L'image rendue est toujours en couleurs, comme dans MATLAB : une
  image en niveaux de gris est d'abord recopiée sur trois plans. La
  classe de l'image d'entrée est conservée.

  Options et valeurs par défaut :
    'FontSize'     12, la hauteur des lettres en pixels
    'TextColor'    'black'
    'BoxColor'     'yellow'
    'BoxOpacity'   0.6 ; zéro supprime le cartouche
    'AnchorPoint'  'LeftTop', ou 'LeftBottom', 'CenterTop',
                   'CenterCenter', 'RightBottom', etc.

  La fonte est tracée dans MATLIBRE_POLICE_5X7, en cinq colonnes sur
  sept lignes, agrandie d'un facteur entier pour approcher la taille
  demandée. MatLibre n'ouvre aucun fichier de fonte du système.

  Exemple :
     I = zeros(60, 200);
     J = insertText(I, [10 20], 'MatLibre', 'FontSize', 14);
     size(J)     % 60 200 3

  Voir aussi INSERTOBJECTANNOTATION, INSERTSHAPE, INSERTMARKER.
```

## `integralFilter`

```
INTEGRALFILTER Filtrage par boîtes sur une image intégrale.
  J = INTEGRALFILTER(II,NOYAU) applique un filtre composé de rectangles
  pondérés, chacun évalué en quatre accès à l'image intégrale II rendue
  par INTEGRALIMAGE. Le coût ne dépend donc pas de la taille des
  rectangles.

  NOYAU est une structure aux champs
    BoundingBoxes  une ligne [x y largeur hauteur] par rectangle,
                   en coordonnées relatives au coin supérieur gauche
    Weights        le poids de chaque rectangle

  Exemple :
     noyau = struct('BoundingBoxes', [1 1 3 3], 'Weights', 1);
     J = integralFilter(integralImage(ones(5)), noyau);
     J(1)   % 9 : la somme d'un carré de trois sur trois

  Voir aussi INTEGRALIMAGE.
```

## `integralImage`

```
INTEGRALIMAGE Image intégrale, ou table de sommes cumulées.
  J = INTEGRALIMAGE(I) rend une matrice d'une ligne et d'une colonne de
  plus que I : J(i+1,j+1) est la somme des pixels du rectangle allant du
  coin supérieur gauche à (i,j). La première ligne et la première
  colonne sont nulles, ce qui évite tout cas particulier.

  La somme sur un rectangle quelconque se lit alors en quatre accès, quel
  que soit sa taille : c'est ce qui rend les filtres à boîte et les
  détecteurs en cascade indépendants de l'échelle.

  Exemple :
     J = integralImage(ones(3));
     J(end, end)   % 9

  Voir aussi INTEGRALFILTER, DETECTFASTFEATURES.
```

## `labeloverlay`

```
LABELOVERLAY Superpose des régions étiquetées à une image.
  B = LABELOVERLAY(A,L) rend l'image A avec, par-dessus, une couleur par
  étiquette de L. L est une matrice d'entiers — zéro pour le fond —, un
  masque logique, ou un tableau catégoriel. La couleur est mélangée à
  l'image, moitié-moitié par défaut, ce qui laisse voir ce qu'il y a
  dessous.

  Options et valeurs par défaut :
    'Colormap'        une couleur distincte par étiquette ; accepte
                      aussi une matrice N-par-3 ou un nom ('jet',
                      'hsv', 'gray')
    'Transparency'    0.5 ; zéro rend la couleur opaque, un la rend
                      invisible
    'IncludedLabels'  la liste des étiquettes à peindre ; les autres
                      restent au fond

  L'image rendue est en couleurs, dans la classe de l'image d'entrée.

  Exemple :
     A = zeros(20, 20);
     L = zeros(20, 20); L(5:10, 5:10) = 1; L(12:18, 12:18) = 2;
     B = labeloverlay(A, L, 'Transparency', 0);
     squeeze(B(7, 7, :)).'

  Voir aussi LABEL2RGB, SUPERPIXELS, BWLABEL, INSERTOBJECTANNOTATION.
```

## `matchFeatures`

```
MATCHFEATURES Appariement de descripteurs par plus proche voisin.
  PAIRES = MATCHFEATURES(D1,D2) rend les couples d'indices appariés. Le
  test du rapport des deux meilleures distances (0.7) élimine les
  appariements ambigus.
```

## `matlibre_agreger_sgm`

```
MATLIBRE_AGREGER_SGM Propage le coût le long de quatre directions.
  S = MATLIBRE_AGREGER_SGM(COUT) ajoute, en chaque pixel et pour chaque
  disparité, le coût cumulé le long des quatre balayages — gauche à
  droite, droite à gauche, haut en bas, bas en haut. La récurrence est

     L(p,d) = C(p,d) + min( L(q,d),
                            L(q,d±1) + P1,
                            min_k L(q,k) + P2 ) - min_k L(q,k)

  où q est le pixel précédent du balayage. Changer de disparité d'un cran
  coûte P1, en changer davantage coûte P2 : la première pénalité laisse
  passer les surfaces inclinées, la seconde retient les sauts sauf là où
  la ressemblance les impose. La soustraction du minimum précédent
  empêche le cumul de croître sans borne.

  S = MATLIBRE_AGREGER_SGM(COUT,P1,P2) impose les deux pénalités.

  Exemple :
     c = rand(4, 5, 3);
     size(matlibre_agreger_sgm(c))    % 4 5 3

  Voir aussi DISPARITYSGM.
```

## `matlibre_appliquer_homographie`

```
MATLIBRE_APPLIQUER_HOMOGRAPHIE Transforme des points par une homographie.
  Q = MATLIBRE_APPLIQUER_HOMOGRAPHIE(H,P) où P a deux colonnes [x y] et
  H est une matrice trois par trois agissant sur des colonnes
  homogènes. Q a deux colonnes, la division par la troisième
  coordonnée étant faite.

  Exemple :
     matlibre_appliquer_homographie([2 0 0; 0 2 0; 0 0 1], [1 1])   % 2 2

  Voir aussi ESTIMATEUNCALIBRATEDRECTIFICATION, RECTIFYSTEREOIMAGES.
```

## `matlibre_boite_transformee`

```
MATLIBRE_BOITE_TRANSFORMEE Rectangle occupé par une image transformée.
  B = MATLIBRE_BOITE_TRANSFORMEE(T,TAILLE) rend [xmin ymin xmax ymax],
  l'enveloppe des quatre coins de l'image une fois transformée par T.

  Exemple :
     matlibre_boite_transformee(eye(3), [4 5])   % 1 1 5 4

  Voir aussi RECTIFYSTEREOIMAGES, MATLIBRE_PROJETER_IMAGE.
```

## `matlibre_cadrage_commun`

```
MATLIBRE_CADRAGE_COMMUN Translation qui ramène deux images rectifiées.
  T = MATLIBRE_CADRAGE_COMMUN(H1,H2,TAILLE) rend la translation qui
  amène le coin supérieur gauche de la réunion des deux images
  transformées en (1,1). La même translation est appliquée aux deux, ce
  qui laisse intact l'alignement des lignes.

  Exemple :
     T = matlibre_cadrage_commun(eye(3), eye(3), [10 10]);   % identité

  Voir aussi ESTIMATEUNCALIBRATEDRECTIFICATION.
```

## `matlibre_camera_distordre`

```
MATLIBRE_CAMERA_DISTORDRE Applique la distorsion de l'objectif.
  La distorsion radiale déplace les points le long du rayon, d'autant
  plus qu'ils sont loin du centre ; la distorsion tangentielle corrige
  le fait que la lentille n'est jamais parfaitement parallèle au
  capteur.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
```

## `matlibre_camera_matrice`

```
MATLIBRE_CAMERA_MATRICE Matrice interne, dans la convention des lignes.
  Accepte une structure de paramètres ou directement une matrice 3x3.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
```

## `matlibre_carte_etiquettes`

```
MATLIBRE_CARTE_ETIQUETTES Une couleur distincte par étiquette.
  C = MATLIBRE_CARTE_ETIQUETTES(SPEC,N) rend N couleurs. SPEC vide donne
  des teintes réparties sur le cercle chromatique, avec saturation et
  clarté alternées pour que deux étiquettes voisines se distinguent même
  quand elles sont nombreuses. SPEC peut aussi être un nom de carte
  ('jet', 'hsv', 'gray') ou une matrice de couleurs.

  Exemple :
     size(matlibre_carte_etiquettes([], 5))   % 5 3

  Voir aussi LABELOVERLAY, SUPERPIXELS, LABEL2RGB.
```

## `matlibre_census`

```
MATLIBRE_CENSUS Transformée de recensement d'une image.
  C = MATLIBRE_CENSUS(I,TAILLE) rend, pour chaque pixel, le tableau des
  comparaisons « ce voisin est-il plus clair que moi ». C est un tableau
  à trois dimensions : un plan logique par voisin de la fenêtre.

  Ce codage ne retient que l'ordre des intensités, pas leur valeur : il
  est donc insensible à un changement d'éclairage entre deux prises de
  vue, ce qui en fait la mesure de ressemblance habituelle en
  stéréovision.

  Exemple :
     C = matlibre_census(magic(6), 3);
     size(C)    % 6 6 8

  Voir aussi DISPARITYSGM, DISPARITYBM.
```

## `matlibre_contraste_local`

```
MATLIBRE_CONTRASTE_LOCAL Force du contour en chaque pixel.
  G = MATLIBRE_CONTRASTE_LOCAL(C) somme, sur tous les plans, le carré
  des différences avec les voisins de gauche-droite et de haut-bas.
  C'est ce qui sert à écarter un germe d'un contour.

  Exemple :
     G = matlibre_contraste_local(cat(3, [0 1; 0 1]));
     size(G)   % 2 2

  Voir aussi SUPERPIXELS.
```

## `matlibre_coordonnee_originale`

```
MATLIBRE_COORDONNEE_ORIGINALE Ramène un point d'un niveau réduit.
  Q = MATLIBRE_COORDONNEE_ORIGINALE(P,ECHELLE) rend la position, dans
  l'image de départ, du point P repéré dans une image réduite ECHELLE
  fois. Le décalage d'un demi-pixel est celui de la convention des
  centres de pixel : le pixel un couvre l'intervalle de 0,5 à 1,5.

  Exemple :
     matlibre_coordonnee_originale([1 1], 2)     % 1.5 1.5

  Voir aussi DETECTORBFEATURES, DETECTBRISKFEATURES, IMRESIZE.
```

## `matlibre_couleur_dessin`

```
MATLIBRE_COULEUR_DESSIN Couleur d'annotation, ramenée à [0,1].
  C = MATLIBRE_COULEUR_DESSIN(SPEC) accepte un nom ('red', 'yellow',
  'black', ...), un triplet dans [0,1], un triplet dans [0,255], une
  liste de noms ou une matrice de triplets, et rend une matrice de
  couleurs à trois colonnes dans [0,1].

  C = MATLIBRE_COULEUR_DESSIN(SPEC,N) répète la couleur pour obtenir N
  lignes lorsqu'une seule est donnée : chaque objet annoté a la sienne.

  Exemple :
     matlibre_couleur_dessin('yellow')     % 1 1 0
     matlibre_couleur_dessin([255 0 0])    % 1 0 0

  Voir aussi INSERTTEXT, INSERTOBJECTANNOTATION, LABELOVERLAY.
```

## `matlibre_cout_recensement`

```
MATLIBRE_COUT_RECENSEMENT Coût d'appariement, par disparité.
  C = MATLIBRE_COUT_RECENSEMENT(G,D,DISPARITES) rend un tableau
  hauteur-largeur-disparités : la distance de Hamming entre les
  recensements du pixel gauche et du pixel droit décalé d'autant. Une
  colonne dont le correspondant sort du cadre reçoit le coût maximal.

  Exemple :
     c = matlibre_cout_recensement(magic(8), magic(8), 0:2);
     c(4, 4, 1)    % 0, l'image appariée à elle-même sans décalage

  Voir aussi DISPARITYSGM, MATLIBRE_CENSUS.
```

## `matlibre_creux_local`

```
MATLIBRE_CREUX_LOCAL Pixel le moins contrasté du carré de trois.
  [I,J] = MATLIBRE_CREUX_LOCAL(G,I,J) déplace le point (I,J) vers son
  voisin de plus faible contraste, dans le voisinage de trois sur trois.

  Exemple :
     G = [5 0; 5 5];
     [i, j] = matlibre_creux_local(G, 1, 1);   % 1 2

  Voir aussi SUPERPIXELS, MATLIBRE_CONTRASTE_LOCAL.
```

## `matlibre_deplacer_image`

```
MATLIBRE_DEPLACER_IMAGE Recale une image sur un champ de déplacement.
  J = MATLIBRE_DEPLACER_IMAGE(I,U,V) rend l'image dont le pixel (y,x)
  vaut I(y+V(y,x), x+U(y,x)), interpolée linéairement. Les coordonnées
  qui sortent du cadre sont ramenées au bord : la comparaison reste
  possible partout.

  Exemple :
     J = matlibre_deplacer_image([1 2 3; 4 5 6], ones(2, 3), zeros(2, 3));
     J(1, 1)   % 2

  Voir aussi OPTICALFLOWFARNEBACK, INTERP2.
```

## `matlibre_disparite_finale`

```
MATLIBRE_DISPARITE_FINALE Choisit la disparité et l'affine au sous-pixel.
  D = MATLIBRE_DISPARITE_FINALE(S,DISPARITES,UNICITE) prend en chaque
  pixel la disparité de coût minimal, ajuste une parabole sur les trois
  coûts qui l'entourent pour gagner une fraction de pixel, et met à NaN
  les pixels dont le second minimum — hors du voisinage immédiat du
  premier — n'est pas plus grand d'au moins UNICITE pour cent.

  Exemple :
     s = cat(3, ones(2), zeros(2), ones(2));
     matlibre_disparite_finale(s, 0:2, 0)    % 1 partout

  Voir aussi DISPARITYSGM.
```

## `matlibre_distance_voisins`

```
MATLIBRE_DISTANCE_VOISINS Distance moyenne de chaque point à ses plus proches.
  Le calcul est fait par blocs : la matrice de toutes les distances
  deux à deux tiendrait mal en mémoire au-delà de quelques milliers de
  points, mais un bloc de lignes tient toujours.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
```

## `matlibre_domine_echelles`

```
MATLIBRE_DOMINE_ECHELLES Un point est-il le plus fort de son échelle ?
  D = MATLIBRE_DOMINE_ECHELLES(SCORES,COUCHES,K,LIGNE,COLONNE,VALEUR)
  compare VALEUR au plus grand score du voisinage de trois sur trois qui
  lui correspond dans les couches voisines, la position étant transposée
  d'une échelle à l'autre. C'est cette comparaison qui n'attribue à un
  coin qu'une seule échelle, la sienne.

  À score égal, le point est gardé dans la couche la plus fine.

  Exemple :
     s = {ones(4), zeros(2)};
     matlibre_domine_echelles(s, [1 2], 1, 2, 2, 1)     % vrai

  Voir aussi DETECTBRISKFEATURES.
```

## `matlibre_echelles_brisk`

```
MATLIBRE_ECHELLES_BRISK Échelles de la pyramide de BRISK.
  E = MATLIBRE_ECHELLES_BRISK(OCTAVES) rend les échelles des couches :
  une octave double l'échelle, et une couche intermédiaire s'intercale à
  une fois et demie. Deux couches consécutives sont donc dans un rapport
  d'environ 1,4, assez proche pour qu'un coin soit vu par au moins deux
  d'entre elles.

  Exemple :
     matlibre_echelles_brisk(3)     % 1 1.5 2 3 4 6

  Voir aussi DETECTBRISKFEATURES.
```

## `matlibre_envoyer_epipole`

```
MATLIBRE_ENVOYER_EPIPOLE Homographie qui repousse un épipôle à l'infini.
  H = MATLIBRE_ENVOYER_EPIPOLE(E,CENTRE) compose trois transformations :
  la translation qui amène CENTRE à l'origine, la rotation qui pose
  l'épipôle E sur l'axe des abscisses, et la matrice qui l'y envoie à
  l'infini. Une fois E à l'infini, les droites épipolaires de l'image
  sont parallèles à l'axe des x.

  E est un vecteur homogène de trois composantes, CENTRE un point [x; y].

  Exemple :
     H = matlibre_envoyer_epipole([1; 0; 0.01], [50; 40]);
     p = H * [1; 0; 0.01];
     abs(p(3)) < 1e-12      % l'épipôle est bien à l'infini

  Voir aussi ESTIMATEUNCALIBRATEDRECTIFICATION.
```

## `matlibre_espace_couleur`

```
MATLIBRE_ESPACE_COULEUR Image ramenée à l'espace où l'on mesure.
  C = MATLIBRE_ESPACE_COULEUR(A,DEJALAB) rend l'image en L*a*b* si elle
  est en couleurs, ou sur un seul plan à l'échelle de L* si elle est en
  niveaux de gris. C'est l'espace où une distance euclidienne se lit
  comme une différence perçue, ce qui est ce que veut le regroupement.

  Exemple :
     size(matlibre_espace_couleur(zeros(4, 4, 3), false))   % 4 4 3

  Voir aussi SUPERPIXELS, RGB2LAB.
```

## `matlibre_etiquettes_entieres`

```
MATLIBRE_ETIQUETTES_ENTIERES Matrice d'étiquettes à partir de ce qu'on a.
  L = MATLIBRE_ETIQUETTES_ENTIERES(E) accepte une matrice d'entiers, un
  masque logique ou un tableau catégoriel, et rend une matrice d'entiers
  où zéro est le fond.

  Exemple :
     matlibre_etiquettes_entieres(logical([0 1; 1 0]))

  Voir aussi LABELOVERLAY, SUPERPIXELS.
```

## `matlibre_expansion_polynomiale`

```
MATLIBRE_EXPANSION_POLYNOMIALE Approche l'image par un polynôme local.
  [B1,B2,A11,A22,A12] = MATLIBRE_EXPANSION_POLYNOMIALE(I,VOISINAGE)
  ajuste, autour de chaque pixel et au sens des moindres carrés
  pondérés, la surface

     f(x,y) = c + b1 x + b2 y + a11 x² + a22 y² + 2 a12 xy

  et rend les coefficients, un plan chacun. C'est l'expansion sur
  laquelle repose le flot optique de Farnebäck : deux images qui ne
  diffèrent que d'un déplacement ont des polynômes liés par une
  relation simple, d'où l'on tire ce déplacement.

  La pondération est gaussienne, d'écart type le quart du voisinage
  augmenté de deux, ce qui donne au bord de la fenêtre un poids faible
  mais non nul.

  Exemple :
     [~, ~, a11] = matlibre_expansion_polynomiale((1:9).^2, 5);
     a11(5)   % 1, le coefficient de x²

  Voir aussi OPTICALFLOWFARNEBACK.
```

## `matlibre_extrema_echelle`

```
MATLIBRE_EXTREMA_ECHELLE Maxima locaux dans le plan et dans l'échelle.
  [L,C] = MATLIBRE_EXTREMA_ECHELLE(REPONSES,NIVEAU,SEUIL,BORD) rend les
  pixels du plan NIVEAU dont la réponse dépasse SEUIL et domine ses
  vingt-six voisins — les huit de son plan, et les neuf de chacun des
  plans voisins. Les pixels à moins de BORD du cadre sont écartés : leur
  filtre déborde de l'image.

  Exemple :
     r = zeros(5, 5, 3); r(3, 3, 2) = 1;
     [l, c] = matlibre_extrema_echelle(r, 2, 0.5, 1);   % 3 3

  Voir aussi DETECTSURFFEATURES.
```

## `matlibre_grille_centres`

```
MATLIBRE_GRILLE_CENTRES Centres de départ répartis sur l'image.
  [X,Y] = MATLIBRE_GRILLE_CENTRES(H,L,PAS) place des points aux nœuds
  d'une grille de maille PAS, sans en poser sur le bord : chacun sera le
  germe d'une région.

  Exemple :
     [x, y] = matlibre_grille_centres(60, 60, 15);
     numel(x)    % 16

  Voir aussi SUPERPIXELS.
```

## `matlibre_gris_255`

```
MATLIBRE_GRIS_255 Image en niveaux de gris, sur l'échelle 0-255.
  G = MATLIBRE_GRIS_255(I) convertit en gris si besoin et ramène les
  valeurs à l'intervalle des images entières, pour que les seuils des
  détecteurs aient partout le même sens.

  Exemple :
     max(max(matlibre_gris_255(ones(2))))    % 255

  Voir aussi DETECTSURFFEATURES, DETECTBRISKFEATURES.
```

## `matlibre_hessienne_approchee`

```
MATLIBRE_HESSIENNE_APPROCHEE Déterminant de la Hessienne, par boîtes.
  [R,T] = MATLIBRE_HESSIENNE_APPROCHEE(INTEGRALE,MARGE,TAILLE,COTE) rend
  le déterminant de la matrice hessienne approchée par des filtres à
  boîte de côté COTE, et la trace, dont le signe distingue une tache
  sombre d'une tache claire.

  Les dérivées secondes d'une gaussienne sont remplacées par des
  rectangles de poids constants, ce qui les rend calculables en temps
  fixe depuis l'image intégrale, quelle que soit l'échelle. Le
  déterminant est corrigé du facteur habituel, qui compense l'écart
  entre la boîte et la gaussienne qu'elle imite, et normalisé par
  l'aire du filtre pour que deux échelles soient comparables.

  Exemple :
     P = padarray(fspecial('gaussian', 41, 4) * 1e4, [30 30], 'replicate');
     R = matlibre_hessienne_approchee(integralImage(P), 30, [41 41], 9);
     R(21, 21) > 0     % la tache est détectée

  Voir aussi DETECTSURFFEATURES, MATLIBRE_SOMME_BOITE.
```

## `matlibre_image_classe`

```
MATLIBRE_IMAGE_CLASSE Ramène une image de [0,1] vers sa classe d'origine.
  J = MATLIBRE_IMAGE_CLASSE(I,CLASSE) est l'opération inverse de
  MATLIBRE_IMAGE_RVB : elle remultiplie et convertit. Une image déjà en
  double ou en single est rendue telle quelle, bornée à [0,1].

  Exemple :
     matlibre_image_classe(0.5, 'uint8')   % 128

  Voir aussi MATLIBRE_IMAGE_RVB.
```

## `matlibre_image_rvb`

```
MATLIBRE_IMAGE_RVB Image en trois plans, valeurs dans [0,1].
  [J,CLASSE] = MATLIBRE_IMAGE_RVB(I) rend l'image en couleurs et en
  flottant, ainsi que la classe de départ pour pouvoir y revenir. Une
  image en niveaux de gris est recopiée sur les trois plans ; une image
  entière est divisée par sa valeur maximale.

  Exemple :
     [J, c] = matlibre_image_rvb(uint8(zeros(4, 4)));
     size(J)   % 4 4 3

  Voir aussi MATLIBRE_IMAGE_CLASSE, INSERTTEXT.
```

## `matlibre_maxima_locaux`

```
MATLIBRE_MAXIMA_LOCAUX Pixels qui dominent leurs huit voisins.
  [L,C] = MATLIBRE_MAXIMA_LOCAUX(CARTE,SEUIL) rend les pixels dont la
  valeur dépasse SEUIL et domine ses huit voisins.

  La comparaison est stricte face aux voisins qui précèdent le pixel
  dans l'ordre de lecture, large face à ceux qui le suivent. Sur un
  plateau — ce qui arrive dès que le score sature —, un seul pixel est
  ainsi retenu, le premier ; une comparaison partout large en rendrait
  tout le plateau.

  Exemple :
     [l, c] = matlibre_maxima_locaux([0 0 0; 0 1 0; 0 0 0], 0.5);   % 2 2
     numel(matlibre_maxima_locaux([0 0 0 0; 0 1 1 0; 0 0 0 0], 0.5))  % 1

  Voir aussi DETECTORBFEATURES, DETECTBRISKFEATURES.
```

## `matlibre_niveau_pyramide`

```
MATLIBRE_NIVEAU_PYRAMIDE Image réduite d'un facteur donné.
  J = MATLIBRE_NIVEAU_PYRAMIDE(I,ECHELLE) rend l'image réduite ECHELLE
  fois. Une échelle de un rend l'image telle quelle, sans passer par un
  rééchantillonnage qui la modifierait inutilement.

  Exemple :
     size(matlibre_niveau_pyramide(zeros(40), 2))    % 20 20

  Voir aussi DETECTORBFEATURES, DETECTBRISKFEATURES, IMRESIZE.
```

## `matlibre_nuage_bornes`

```
MATLIBRE_NUAGE_BORNES Étendue d'un nuage selon un axe.
  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
```

## `matlibre_nuage_copier`

```
MATLIBRE_NUAGE_COPIER Nuage de mêmes attributs, aux points donnés.
  GARDE, s'il est donné, indique quels points d'origine sont conservés,
  ce qui permet de trier couleurs et intensités avec eux.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
```

## `matlibre_nuage_grille`

```
MATLIBRE_NUAGE_GRILLE Moyenne des points par cube d'une grille.
  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
```

## `matlibre_nuage_points`

```
MATLIBRE_NUAGE_POINTS Coordonnées d'un nuage, ramenées en trois colonnes.
  Un nuage organisé — un tableau M×N×3 — est déplié ligne à ligne ; un
  nuage déjà rangé passe tel quel. Accepte aussi une matrice brute, ce
  qui évite d'envelopper un nuage pour un seul appel.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
```

## `matlibre_orientation_centroide`

```
MATLIBRE_ORIENTATION_CENTROIDE Direction d'un point d'intérêt.
  A = MATLIBRE_ORIENTATION_CENTROIDE(I,LIGNE,COLONNE,RAYON) rend l'angle
  du vecteur qui va du pixel au centre de masse des intensités de son
  disque de rayon RAYON. Cette direction tourne avec l'image : c'est ce
  qui permet de comparer deux vues d'un même point pris sous des angles
  différents.

  Exemple :
     I = zeros(31); I(16, 20:31) = 1;
     matlibre_orientation_centroide(I, 16, 16, 10)     % environ 0

  Voir aussi DETECTORBFEATURES.
```

## `matlibre_plan_moindres_carres`

```
MATLIBRE_PLAN_MOINDRES_CARRES Plan le plus proche d'un nuage.
  La normale est le vecteur propre de plus petite valeur propre de la
  covariance : la direction dans laquelle le nuage s'étend le moins.
  C'est la solution des moindres carrés totaux, qui minimise la distance
  au plan et non l'écart vertical.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
```

## `matlibre_plan_par_trois`

```
MATLIBRE_PLAN_PAR_TROIS Plan passant par trois points.
  Rend [a b c d] avec a²+b²+c² = 1, ou rien si les trois points sont
  alignés.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
```

## `matlibre_police_5x7`

```
MATLIBRE_POLICE_5X7 Motif binaire d'un texte, cinq colonnes par lettre.
  M = MATLIBRE_POLICE_5X7(TEXTE) rend une matrice logique de sept
  lignes : le dessin du texte dans une fonte de chiffres tracée ici même,
  cinq colonnes par caractère et une colonne blanche entre deux.

  Le tableau couvre l'ASCII imprimable, de l'espace au tilde. Un
  caractère hors de cet intervalle est dessiné comme un espace.

  Exemple :
     m = matlibre_police_5x7('ok');
     size(m)    % 7 11

  Voir aussi INSERTTEXT, INSERTOBJECTANNOTATION.
```

## `matlibre_pose_optimale`

```
MATLIBRE_POSE_OPTIMALE Transformation rigide qui superpose deux jeux appariés.
  C'est le problème de Procuste orthogonal : après avoir centré les deux
  nuages, la rotation optimale se lit sur la décomposition en valeurs
  singulières de leur produit croisé. Le déterminant est corrigé pour
  écarter les réflexions, qui minimiseraient l'écart sans être des
  rotations.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
```

## `matlibre_produit_vectoriel_matrice`

```
MATLIBRE_PRODUIT_VECTORIEL_MATRICE Matrice antisymétrique d'un vecteur.
  S = MATLIBRE_PRODUIT_VECTORIEL_MATRICE(V) rend la matrice telle que
  S*W soit le produit vectoriel de V et de W, quel que soit W.

  Exemple :
     S = matlibre_produit_vectoriel_matrice([0 0 1]);
     S * [1; 0; 0]      % 0 1 0

  Voir aussi ESTIMATEUNCALIBRATEDRECTIFICATION, CROSS.
```

## `matlibre_projeter_image`

```
MATLIBRE_PROJETER_IMAGE Applique une transformation projective à une image.
  J = MATLIBRE_PROJETER_IMAGE(I,T,CADRE,REMPLISSAGE) rend l'image
  transformée par T, échantillonnée sur le rectangle CADRE donné en
  [xmin ymin largeur hauteur] dans les coordonnées de sortie. T suit la
  convention de MATLAB : un point s'écrit en ligne, [x y 1] * T.

  Le calcul va de la sortie vers l'entrée — chaque pixel de sortie
  cherche d'où il vient —, ce qui évite les trous que laisserait le
  parcours inverse. L'interpolation est bilinéaire ; ce qui tombe hors
  de l'image d'entrée reçoit REMPLISSAGE.

  Exemple :
     J = matlibre_projeter_image(magic(4), eye(3), [1 1 4 4], 0);
     isequal(J, magic(4))     % vrai

  Voir aussi RECTIFYSTEREOIMAGES, ESTIMATEUNCALIBRATEDRECTIFICATION.
```

## `matlibre_rattacher_orphelins`

```
MATLIBRE_RATTACHER_ORPHELINS Donne une région aux pixels laissés de côté.
  L = MATLIBRE_RATTACHER_ORPHELINS(L,ORPHELINS,X,Y) attribue à chaque
  pixel non étiqueté le centre spatialement le plus proche. Cela arrive
  quand aucune fenêtre de recherche ne l'a couvert.

  Exemple :
     L = matlibre_rattacher_orphelins(zeros(2), true(2), 1, 1);

  Voir aussi SUPERPIXELS.
```

## `matlibre_recentrer`

```
MATLIBRE_RECENTRER Recalcule le centre de chaque région.
  [X,Y,COULEUR] = MATLIBRE_RECENTRER(C,L,K,X,Y,COULEUR) remplace chaque
  centre par la moyenne des pixels qui lui sont rattachés — position et
  couleur. Une région vide garde son centre précédent.

  Exemple :
     C = zeros(2, 2);
     [x, y] = matlibre_recentrer(C, ones(2), 1, 1, 1, 0);   % 1.5 1.5

  Voir aussi SUPERPIXELS.
```

## `matlibre_regions_connexes`

```
MATLIBRE_REGIONS_CONNEXES Rend connexe et renumérote un étiquetage.
  [M,N] = MATLIBRE_REGIONS_CONNEXES(L,TAILLEMIN) découpe chaque
  étiquette en ses morceaux connexes — voisinage de quatre — et
  renumérote de un à N. Un morceau de moins de TAILLEMIN pixels est
  fondu dans le morceau voisin déjà numéroté, ce qui évite les régions
  d'un pixel que le regroupement laisse parfois derrière lui.

  Exemple :
     L = [1 1 2; 1 1 2; 3 3 2];
     [M, n] = matlibre_regions_connexes(L, 0);   % n = 3

  Voir aussi SUPERPIXELS, BWLABEL, PCSEGDIST.
```

## `matlibre_reponse_harris`

```
MATLIBRE_REPONSE_HARRIS Carte de réponse du détecteur de Harris.
  R = MATLIBRE_REPONSE_HARRIS(I) rend, en chaque pixel, le déterminant
  moins CONSTANTE fois le carré de la trace de la matrice des moments du
  gradient, lissée par une gaussienne. La réponse est grande là où le
  gradient change de direction — un coin — et faible le long d'un
  contour, où il ne change pas.

  R = MATLIBRE_REPONSE_HARRIS(I,CONSTANTE) impose la constante, 0,04 par
  défaut.

  Exemple :
     I = zeros(21); I(1:10, 1:10) = 1;
     R = matlibre_reponse_harris(I);
     R(10, 10) > 0     % le coin du carré répond

  Voir aussi DETECTHARRISFEATURES, DETECTORBFEATURES.
```

## `matlibre_restreindre_zone`

```
MATLIBRE_RESTREINDRE_ZONE Ne garde que les points d'un rectangle.
  [P,A,B,C] = MATLIBRE_RESTREINDRE_ZONE(ZONE,P,A,B,C) où ZONE vaut
  [x y largeur hauteur]. Une zone vide laisse tout passer.

  Exemple :
     p = matlibre_restreindre_zone([1 1 5 5], [3 3; 9 9], [1; 2], [], []);
     size(p, 1)    % 1

  Voir aussi DETECTSURFFEATURES, DETECTBRISKFEATURES, DETECTORBFEATURES.
```

## `matlibre_score_fast`

```
MATLIBRE_SCORE_FAST Force de coin au sens de FAST, en chaque pixel.
  S = MATLIBRE_SCORE_FAST(I) rend, pour chaque pixel, le plus grand
  seuil auquel il reste un coin FAST : le maximum, sur les seize arcs de
  neuf voisins consécutifs du cercle de Bresenham, du plus petit écart
  au centre. Un pixel qui n'est pas un coin reçoit zéro.

  C'est la définition même du détecteur : un coin est un point dont un
  arc entier du cercle est plus clair, ou plus sombre, que le centre.
  Le score ainsi défini sert à comparer des coins entre eux et à les
  comparer d'une échelle à l'autre.

  Exemple :
     I = zeros(11); I(1:5, 1:5) = 1;
     S = matlibre_score_fast(I);
     S(6, 6) > 0      % le coin du carré est détecté

  Voir aussi DETECTFASTFEATURES, DETECTBRISKFEATURES, DETECTORBFEATURES.
```

## `matlibre_somme_boite`

```
MATLIBRE_SOMME_BOITE Somme d'un rectangle décalé, en chaque pixel.
  S = MATLIBRE_SOMME_BOITE(INTEGRALE,MARGE,TAILLE,BOITE) rend, pour
  chaque pixel (y,x) d'une image de taille TAILLE, la somme des pixels du
  rectangle allant de (y+BOITE(1), x+BOITE(3)) à (y+BOITE(2), x+BOITE(4)).
  INTEGRALE est l'image intégrale de l'image élargie de MARGE de chaque
  côté, ce qui permet aux rectangles de déborder sans cas particulier.

  Quatre accès suffisent quelle que soit la taille du rectangle : c'est
  ce qui rend le détecteur de Hessienne approchée indépendant de
  l'échelle.

  Exemple :
     P = padarray(ones(4), [2 2], 'replicate');
     S = matlibre_somme_boite(integralImage(P), 2, [4 4], [-1 1 -1 1]);
     S(2, 2)     % 9

  Voir aussi DETECTSURFFEATURES, INTEGRALIMAGE, INTEGRALFILTER.
```

## `matlibre_sommet_quadratique`

```
MATLIBRE_SOMMET_QUADRATIQUE Position sous-pixel d'un maximum local.
  [DL,DC] = MATLIBRE_SOMMET_QUADRATIQUE(CARTE,LIGNE,COLONNE) ajuste une
  parabole sur les trois valeurs qui entourent le maximum dans chaque
  direction et rend le décalage de son sommet, borné à un demi-pixel.
  Un maximum trouvé sur une image réduite gagne ainsi la précision que
  la réduction lui avait fait perdre.

  Exemple :
     c = [0 0 0; 1 2 1.5; 0 0 0];
     [~, dc] = matlibre_sommet_quadratique(c, 2, 2);   % environ 0.1

  Voir aussi DETECTBRISKFEATURES.
```

## `matlibre_textes_cellules`

```
MATLIBRE_TEXTES_CELLULES Normalise l'argument texte des annotations.
  L = MATLIBRE_TEXTES_CELLULES(TEXTE,N) rend un tableau de cellules de N
  chaînes. TEXTE peut être une chaîne — répétée —, un tableau de
  cellules, un vecteur de nombres, ou un tableau de caractères dont
  chaque ligne est une étiquette.

  Exemple :
     matlibre_textes_cellules([1 2], 2)   % {'1', '2'}

  Voir aussi INSERTTEXT, INSERTOBJECTANNOTATION.
```

## `matlibre_transformation_rigide`

```
MATLIBRE_TRANSFORMATION_RIGIDE Matrice homogène 4x4 d'une transformation.
  Accepte une matrice 4x4 dans l'une ou l'autre convention, une
  rotation 3x3, ou une structure à champ T ou A. La convention de
  MATLAB place la translation en dernière ligne ; on la reconnaît à ce
  que sa dernière colonne vaut [0 0 0 1].

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
```

## `matlibre_trier_points`

```
MATLIBRE_TRIER_POINTS Range des points d'intérêt du plus fort au plus faible.
  [P,A,B,C] = MATLIBRE_TRIER_POINTS(P,A,B,C) trie les lignes par valeur
  décroissante de A — la métrique — et réordonne les autres colonnes de
  la même façon.

  Exemple :
     [p, m] = matlibre_trier_points([1 1; 2 2], [3; 7], [], []);
     m(1)    % 7

  Voir aussi DETECTSURFFEATURES, DETECTBRISKFEATURES, SELECTSTRONGEST.
```

## `opticalFlowFarneback`

```
OPTICALFLOWFARNEBACK Flot optique par expansion polynomiale.
  [U,V] = OPTICALFLOWFARNEBACK(I1,I2) rend le déplacement estimé en
  chaque pixel entre les deux images. La méthode approche le voisinage
  de chaque pixel par un polynôme du second degré : deux images qui ne
  diffèrent que d'un déplacement ont des polynômes liés par

     A d = (b1 - b2) / 2

  où A est la partie quadratique et b la partie linéaire. Le système est
  résolu sur un voisinage, ce qui le rend inversible même là où l'image
  n'a de structure que dans une direction.

  Contrairement à Lucas-Kanade, la méthode part d'une pyramide : le
  déplacement est d'abord estimé sur une image réduite, puis affiné à
  chaque agrandissement. Elle attrape ainsi des déplacements de
  plusieurs pixels.

  Options et valeurs par défaut :
    'NumPyramidLevels'  3
    'PyramidScale'      0.5, le rapport d'un niveau au suivant
    'NumIterations'     3, par niveau
    'NeighborhoodSize'  5, la fenêtre de l'ajustement polynomial
    'FilterSize'        15, la fenêtre où le système est moyenné

  Exemple :
     rng(1);
     A = imfilter(rand(60, 60), fspecial('gaussian', 9, 2));
     B = matlibre_deplacer_image(A, -3 * ones(60), zeros(60));
     [u, v] = opticalFlowFarneback(A, B);
     median(median(u(20:40, 20:40)))    % environ 3

  Voir aussi OPTICALFLOWLK, OPTICALFLOWHS, MATLIBRE_EXPANSION_POLYNOMIALE.
```

## `opticalFlowHS`

```
OPTICALFLOWHS Flot optique de Horn et Schunck.
  [VX,VY] = OPTICALFLOWHS(I1,I2) estime le déplacement de chaque pixel
  entre deux images. La méthode complète l'équation du flot optique,
  qui ne donne qu'une contrainte pour deux inconnues, par une hypothèse
  de régularité : le champ doit varier lentement.

  On minimise
     somme (Ix u + Iy v + It)^2 + alpha^2 (|grad u|^2 + |grad v|^2)
  dont les équations d'Euler-Lagrange donnent une itération de
  Gauss-Seidel où chaque vitesse est ramenée vers la moyenne de ses
  voisines, corrigée par le résidu de la contrainte.

  À la différence de Lucas et Kanade, qui suppose le flot constant sur
  un voisinage et laisse indéterminées les zones sans texture, la
  régularisation propage l'information depuis les bords : le champ est
  dense partout.

  Options : 'Smoothness' (1, le poids alpha) et 'MaxIteration' (100).

  Exemple :
     I = zeros(30); I(10:20, 10:20) = 1;
     J = zeros(30); J(10:20, 12:22) = 1;
     [vx, vy] = opticalFlowHS(I, J);
     mean(mean(vx(12:18, 12:18)))   % voisin de 2

  Voir aussi OPTICALFLOWLK.
```

## `opticalFlowLK`

```
OPTICALFLOWLK Flot optique par la méthode de Lucas-Kanade.
  [U,V] = OPTICALFLOWLK(I1,I2,FENETRE) rend les deux composantes du
  déplacement estimé en chaque pixel, de la première image vers la
  seconde. FENETRE est le côté du voisinage employé, cinq par défaut.

  L'hypothèse est que la luminance se conserve : un point garde sa
  valeur en se déplaçant, d'où l'équation Ix u + Iy v + It = 0. Elle ne
  suffit pas à déterminer les deux inconnues en un seul pixel — c'est le
  problème de l'ouverture, qui ne laisse voir que la composante
  perpendiculaire à un contour. Lucas et Kanade la lèvent en supposant
  le déplacement constant sur le voisinage, ce qui donne autant
  d'équations que de pixels de la fenêtre.

  Le déplacement n'est estimé que là où la matrice normale est
  inversible : dans une zone uniforme ou le long d'un contour droit,
  elle est singulière et le flot rendu vaut zéro. Ce n'est pas un échec
  du calcul mais l'absence d'information.

  La méthode est locale et linéarisée : elle ne retrouve que les petits
  déplacements, de l'ordre du pixel. Au-delà, il faut une pyramide.

  Le signe suit la convention d'OPTICALFLOWFARNEBACK : un objet qui se
  déplace vers la droite donne un U positif.

  Exemple :
     A = zeros(40); A(15:25, 15:25) = 1;
     [u, v] = opticalFlowLK(A, circshift(A, [0 1]), 9);
     median(median(u(12:28, 12:28)))      % environ 1 : vers la droite

  Voir aussi OPTICALFLOWFARNEBACK, IMFILTER.
```

## `pcdenoise`

```
PCDENOISE Retire les points aberrants d'un nuage.
  Q = PCDENOISE(P) écarte les points dont la distance moyenne à leurs
  voisins s'écarte trop de la distance moyenne du nuage entier.

  Un point de mesure isolé n'est pas une petite erreur : c'est un point
  qui n'existe pas. Le filtre repose sur cette idée — un vrai point a
  des voisins proches, un artefact n'en a pas.

  PCDENOISE(...,'NumNeighbors',K) fixe le nombre de voisins (quatre),
  'Threshold',T le nombre d'écarts types toléré (un).

  [Q,I,R] = PCDENOISE(...) rend les indices gardés et rejetés.

  Exemple :
     p = pointCloud([randn(500,3); 20 * randn(5,3)]);
     q = pcdenoise(p);

  Voir aussi PCDOWNSAMPLE, POINTCLOUD, PCSEGDIST.
```

## `pcdownsample`

```
PCDOWNSAMPLE Allège un nuage de points.
  Q = PCDOWNSAMPLE(P,'random',PART) garde une fraction des points,
  tirée au hasard.
  Q = PCDOWNSAMPLE(P,'gridAverage',PAS) découpe l'espace en cubes de
  côté PAS et remplace les points de chaque cube par leur moyenne.
  Q = PCDOWNSAMPLE(P,'nonuniformGridSample',N) garde environ un point
  par cube, la taille du cube étant choisie pour qu'il reste N points.

  La moyenne par grille ne se contente pas d'écarter des points : elle
  les remplace par leur barycentre. Le nuage allégé est donc moins
  bruité que le nuage d'origine, là où un tirage au hasard garde le
  bruit tel quel.

  Exemple :
     q = pcdownsample(pointCloud(rand(10000, 3)), 'gridAverage', 0.1);

  Voir aussi PCDENOISE, POINTCLOUD, PCMERGE.
```

## `pcfitplane`

```
PCFITPLANE Ajuste un plan à un nuage de points, par tirages aléatoires.
  [M,DEDANS,DEHORS,E] = PCFITPLANE(P,D) cherche le plan qui rassemble le
  plus de points à moins de D de lui. M porte les quatre coefficients
  a, b, c, d du plan a*x + b*y + c*z + d = 0, et sa normale.

  La méthode est celle du consensus par échantillonnage : on tire trois
  points au hasard, on compte combien de points le plan qu'ils
  définissent rassemble, et l'on recommence. Contrairement aux moindres
  carrés, un point aberrant n'y pèse rien : il n'appartient simplement à
  aucun consensus.

  PCFITPLANE(P,D,VECTEUR,ANGLE) n'accepte que les plans dont la normale
  s'écarte du vecteur de moins de ANGLE degrés — c'est ainsi qu'on
  cherche un sol plutôt qu'un mur.

  Exemple :
     p = pointCloud([rand(500,2)*10, 0.01*randn(500,1)]);
     m = pcfitplane(p, 0.05);
     m.Parameters

  Voir aussi PCSEGDIST, PCNORMALS, PCREGISTERICP, POINTCLOUD.
```

## `pcmerge`

```
PCMERGE Fusionne deux nuages de points.
  Q = PCMERGE(P1,P2,PAS) réunit les deux nuages et fond en un seul
  point ceux qui tombent dans le même cube de côté PAS.

  Sans cette fusion, recoller deux relevés d'une même scène doublerait
  la densité dans leur recouvrement, ce qui fausse tout calcul de
  normale ou de plan.

  Exemple :
     q = pcmerge(pointCloud(rand(100,3)), pointCloud(rand(100,3)), 0.05);

  Voir aussi PCDOWNSAMPLE, PCREGISTERICP, POINTCLOUD.
```

## `pcnormals`

```
PCNORMALS Normales estimées en chaque point d'un nuage.
  N = PCNORMALS(P) rend, pour chaque point, la direction perpendiculaire
  à la surface locale. PCNORMALS(P,K) prend K voisins (six par défaut).

  La normale est le vecteur propre associé à la plus petite valeur
  propre de la covariance des voisins : la direction dans laquelle le
  voisinage s'étend le moins est celle qui sort de la surface.

  Le signe reste indéterminé — rien, dans un nuage, ne dit quel côté
  est l'extérieur.

  Exemple :
     p = pointCloud([rand(500,2), zeros(500,1)]);
     n = pcnormals(p);            % toutes selon z

  Voir aussi PCFITPLANE, POINTCLOUD, PCDENOISE.
```

## `pcregistericp`

```
PCREGISTERICP Recale deux nuages de points, par plus proches voisins.
  [T,Q,E] = PCREGISTERICP(MOBILE,FIXE) cherche la transformation rigide
  qui superpose le premier nuage au second, et rend le nuage déplacé
  ainsi que l'erreur quadratique moyenne restante.

  L'algorithme alterne deux étapes évidentes prises séparément : à
  correspondances données, la transformation optimale se calcule d'un
  coup par décomposition en valeurs singulières ; à transformation
  donnée, les correspondances sont les plus proches voisins. Répéter
  les deux fait décroître l'erreur à chaque tour, ce qui garantit la
  convergence — vers un minimum local, non forcément le bon.

  PCREGISTERICP(...,'MaxIterations',N) borne le nombre de tours (vingt),
  'Tolerance',[T R] les seuils d'arrêt en translation et en rotation,
  'InitialTransform',T0 part d'une pose donnée.

  Exemple :
     a = pointCloud(rand(300, 3));
     T = [rotz(10), [0.1; 0.05; 0]; 0 0 0 1];
     b = pctransform(a, T);
     Trouve = pcregistericp(b, a);

  Voir aussi PCTRANSFORM, PCMERGE, POINTCLOUD.
```

## `pcsegdist`

```
PCSEGDIST Sépare un nuage en groupes, par distance.
  [L,N] = PCSEGDIST(P,D) donne à chaque point le numéro de son groupe :
  deux points appartiennent au même groupe s'il existe une chaîne de
  points consécutifs distants de moins de D.

  C'est la segmentation la plus simple qui soit, et souvent la bonne :
  dans une scène, les objets sont séparés par du vide.

  PCSEGDIST(...,'NumClusterPoints',[MIN MAX]) écarte les groupes trop
  petits ou trop gros, dont les points reçoivent l'étiquette zéro.

  Exemple :
     p = pointCloud([randn(200,3); randn(200,3) + 20]);
     [l, n] = pcsegdist(p, 2);      % n = 2

  Voir aussi PCFITPLANE, PCDENOISE, POINTCLOUD.
```

## `pctransform`

```
PCTRANSFORM Applique une transformation rigide à un nuage de points.
  Q = PCTRANSFORM(P,T) déplace le nuage. T est une matrice homogène
  4x4, ou une matrice 3x3 de rotation, ou une structure portant les
  champs T ou A.

  La convention retenue est celle des colonnes : le point est un
  vecteur colonne, et la transformation le multiplie à gauche. Une
  matrice donnée dans la convention de MATLAB — translation en
  dernière ligne — est reconnue et transposée.

  Les normales, s'il y en a, subissent la seule rotation : une normale
  ne se translate pas.

  Exemple :
     T = [eye(3), [1;2;3]; 0 0 0 1];
     q = pctransform(pointCloud(rand(100,3)), T);

  Voir aussi POINTCLOUD, PCREGISTERICP, PCMERGE.
```

## `pointCloud`

```
POINTCLOUD Nuage de points en trois dimensions.
  P = POINTCLOUD(XYZ) range un nuage : XYZ est une matrice à trois
  colonnes, une ligne par point, ou un tableau M×N×3 pour un nuage
  organisé — celui que rend une caméra de profondeur, où le voisinage
  dans l'image dit quelque chose du voisinage dans l'espace.

  POINTCLOUD(...,'Color',C,'Normal',N,'Intensity',I) attache une
  couleur, une normale et une intensité à chaque point.

  Les propriétés calculées XLimits, YLimits, ZLimits et Count donnent
  l'étendue et le nombre de points.

  Exemple :
     p = pointCloud(rand(1000, 3));
     p.Count
     pcdownsample(p, 'gridAverage', 0.1)

  Voir aussi PCDOWNSAMPLE, PCDENOISE, PCFITPLANE, PCREGISTERICP,
  PCTRANSFORM, PCMERGE, PCNORMALS, PCSEGDIST.
```

## `pointsToWorld`

```
POINTSTOWORLD Relève des points image sur le plan z égal à zéro du monde.
  P = POINTSTOWORLD(PARAMS,R,T,POINTS) rend les coordonnées dans le
  monde des points image, en supposant qu'ils appartiennent au plan
  z = 0.

  Une image ne suffit pas à situer un point dans l'espace : elle donne
  un rayon, non un point. Il faut donc une hypothèse de plus, et
  celle-ci — le point est au sol — est la plus courante.

  Exemple :
     c = cameraIntrinsics([800 800], [320 240], [480 640]);
     pointsToWorld(c, eye(3), [0 0 10], [320 240])    % [0 0]

  Voir aussi WORLDTOIMAGE, CAMERAMATRIX, TRIANGULATE.
```

## `reconstructScene`

```
RECONSTRUCTSCENE Reconstruit une scène à partir d'une carte de disparités.
  P = RECONSTRUCTSCENE(D,Q) rend, pour chaque pixel, ses coordonnées
  dans l'espace. D est la carte de disparités d'une paire rectifiée, Q
  la matrice de reprojection 4x4 que rend la rectification.

  La disparité est l'écart horizontal entre les deux vues d'un même
  point : elle décroît avec la distance, et c'est tout le principe de
  la stéréovision. Un pixel de disparité nulle ou négative n'a pas été
  apparié ; sa profondeur vaut l'infini.

  Exemple :
     Q = [1 0 0 -320; 0 1 0 -240; 0 0 0 800; 0 0 1/0.1 0];
     P = reconstructScene(disparites, Q);

  Voir aussi DISPARITYBM, DISPARITYSGM, RECTIFYSTEREOIMAGES, TRIANGULATE.
```

## `rectifyStereoImages`

```
RECTIFYSTEREOIMAGES Redresse une paire stéréo.
  [J1,J2] = RECTIFYSTEREOIMAGES(I1,I2,T1,T2) applique les deux
  transformations projectives rendues par
  ESTIMATEUNCALIBRATEDRECTIFICATION. Dans les images redressées, deux
  points correspondants sont sur la même ligne : la disparité se lit
  alors comme un simple décalage horizontal.

  Options et valeurs par défaut :
    'OutputView'   'valid' — le plus grand rectangle commun aux deux
                   images redressées — ou 'full', qui garde tout
    'FillValues'   0, la valeur donnée à ce qui vient de hors-champ
    'InterpolationMethod'  'linear', accepté pour la compatibilité

  Les deux images de sortie ont la même taille et le même cadrage, ce
  qui est nécessaire pour que la comparaison ligne à ligne ait un sens.

  Exemple :
     F = estimateFundamentalMatrix(p1, p2);
     [T1, T2] = estimateUncalibratedRectification(F, p1, p2, size(I1));
     [J1, J2] = rectifyStereoImages(I1, I2, T1, T2, 'OutputView', 'full');
     carte = disparitySGM(J1, J2);

  Voir aussi ESTIMATEUNCALIBRATEDRECTIFICATION, DISPARITYSGM, DISPARITYBM.
```

## `rotationMatrixToVector`

```
ROTATIONMATRIXTOVECTOR Axe et angle d'une matrice de rotation.
  V = ROTATIONMATRIXTOVECTOR(R) rend le vecteur dont la direction est
  l'axe de rotation et la norme l'angle. C'est la réciproque de
  ROTATIONVECTORTOMATRIX.

  L'angle se lit sur la trace, acos((trace(R) - 1) / 2), et l'axe sur la
  partie antisymétrique. Les deux cas dégénérés sont traités à part :
  l'angle nul, où l'axe est indéterminé, et l'angle pi, où la partie
  antisymétrique s'annule et où l'axe se lit sur la diagonale de R + I.

  Exemple :
     rotationMatrixToVector(rotationVectorToMatrix([0.1 0.2 0.3]))
     % [0.1 0.2 0.3]

  Voir aussi ROTATIONVECTORTOMATRIX.
```

## `rotationVectorToMatrix`

```
ROTATIONVECTORTOMATRIX Formule de Rodrigues.
  R = ROTATIONVECTORTOMATRIX(V) rend la matrice de rotation dont l'axe
  est la direction de V et l'angle sa norme :

     R = I + sin(theta) K + (1 - cos(theta)) K^2

  où K est la matrice antisymétrique associée à l'axe unitaire. Trois
  nombres suffisent donc à décrire une rotation, là où la matrice en
  compte neuf liés par six contraintes.

  Exemple :
     R = rotationVectorToMatrix([0 0 pi/2]);
     round(R * [1; 0; 0])   % [0; 1; 0]

  Voir aussi ROTATIONMATRIXTOVECTOR.
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

## `selectUniform`

```
SELECTUNIFORM Sélection de points répartis sur toute l'image.
  [P,I] = SELECTUNIFORM(POSITIONS,N,TAILLE) retient N points en les
  prenant dans une grille de cases, une case après l'autre : au lieu de
  garder les N plus forts, qui se concentrent souvent sur une seule
  texture, on garantit une couverture de toute l'image.

  C'est ce qu'il faut pour estimer une transformation géométrique : des
  points groupés au même endroit contraignent mal.

  Exemple :
     p = selectUniform(rand(500, 2) * 100, 20, [100 100]);
     size(p, 1)   % 20

  Voir aussi SELECTSTRONGEST, DETECTHARRISFEATURES.
```

## `stereoAnaglyph`

```
STEREOANAGLYPH Anaglyphe rouge-cyan d'une paire stéréoscopique.
  J = STEREOANAGLYPH(G,D) place l'image gauche dans le canal rouge et
  l'image droite dans les canaux vert et bleu. Vue à travers des
  lunettes rouge-cyan, chaque œil ne reçoit que son image et le relief
  apparaît.

  Les deux images doivent avoir la même taille ; celles en couleur sont
  converties en niveaux de gris.

  Exemple :
     a = stereoAnaglyph(zeros(4), ones(4));
     a(1, 1, :)   % [0 1 1] : noir à gauche, blanc à droite

  Voir aussi DISPARITYBM.
```

## `superpixels`

```
SUPERPIXELS Découpe une image en régions homogènes de taille voisine.
  [L,N] = SUPERPIXELS(A,NOMBRE) rend une matrice d'étiquettes qui
  partage l'image en environ NOMBRE régions, et le nombre de régions
  obtenu. Chaque région rassemble des pixels voisins et de couleur
  proche : c'est un regroupement par les k-moyennes dans l'espace formé
  de la couleur et de la position, la recherche étant limitée au
  voisinage de chaque centre — ce qui rend le coût linéaire.

  Options et valeurs par défaut :
    'Compactness'    10 ; grand, il donne des régions carrées, petit,
                     il colle aux contours
    'NumIterations'  10
    'Method'         'slic0' — la compacité s'ajuste par région — ou
                     'slic', qui la garde fixe
    'IsInputLab'     false ; l'image couleur est convertie en L*a*b*,
                     où une distance vaut une différence perçue

  Les régions rendues sont connexes : les morceaux détachés sont
  rattachés à la région voisine, et les trop petits fondus dedans.

  Exemple :
     A = zeros(60, 60); A(:, 31:end) = 1;
     [L, n] = superpixels(A, 16);
     % le contour vertical n'est traversé par aucune région
     all(L(:, 30) ~= L(:, 31))

  Voir aussi LABELOVERLAY, BWLABEL, LABEL2RGB, PCSEGDIST.
```

## `triangulate`

```
TRIANGULATE Reconstruction de points par intersection de rayons.
  P = TRIANGULATE(P1,P2,M1,M2) rend les coordonnées trois dimensions des
  points vus en P1 dans la première caméra et en P2 dans la seconde, les
  matrices de projection étant M1 et M2.

  Chaque correspondance donne quatre équations linéaires homogènes en
  les quatre coordonnées homogènes du point : la solution est le vecteur
  singulier associé à la plus petite valeur singulière. Deux rayons ne
  se coupent jamais exactement en présence de bruit ; cette solution est
  celle qui minimise l'erreur algébrique.

  Les matrices sont acceptées en 3x4, convention usuelle, ou en 4x3,
  convention de MATLAB, auquel cas elles sont transposées.

  [P,E] = TRIANGULATE(...) rend aussi l'erreur de reprojection moyenne
  de chaque point, en pixels.

  Exemple :
     M1 = [eye(3), zeros(3,1)];
     M2 = [eye(3), [-1;0;0]];
     triangulate([0 0], [-1 0], M1, M2)   % [0 0 1]

  Voir aussi ESTIMATEFUNDAMENTALMATRIX, EPIPOLARLINE.
```

## `undistortPoints`

```
UNDISTORTPOINTS Corrige la distorsion d'objectif sur des points image.
  Q = UNDISTORTPOINTS(P,PARAMS) rend les coordonnées qu'auraient les
  points si l'objectif était parfait.

  Le modèle de distorsion se calcule dans un sens — du point idéal vers
  le point observé — et ne s'inverse pas en forme fermée. L'inversion se
  fait donc par itération : on part du point observé, on lui applique la
  distorsion, on corrige de l'écart, et l'on recommence. Quelques tours
  suffisent, la distorsion étant petite.

  [Q,R] = UNDISTORTPOINTS(...) rend aussi l'erreur de reprojection.

  Exemple :
     c = cameraIntrinsics([800 800], [320 240], [480 640], ...
                          'RadialDistortion', [-0.2 0.05]);
     undistortPoints([100 100], c)

  Voir aussi WORLDTOIMAGE, CAMERAPARAMETERS, CAMERAINTRINSICS.
```

## `worldToImage`

```
WORLDTOIMAGE Projette des points du monde sur le plan image.
  P = WORLDTOIMAGE(PARAMS,R,T,POINTS) rend les coordonnées image des
  points donnés. POINTS est une matrice à trois colonnes.

  [P,DEVANT] = WORLDTOIMAGE(...) dit lesquels sont devant la caméra :
  un point derrière se projette aussi, mais au mauvais endroit, et la
  projection ne le signale pas d'elle-même.

  WORLDTOIMAGE(...,'ApplyDistortion',true) applique la distorsion de
  l'objectif après la projection.

  Exemple :
     c = cameraIntrinsics([800 800], [320 240], [480 640]);
     worldToImage(c, eye(3), [0 0 10], [0 0 0])    % [320 240]

  Voir aussi POINTSTOWORLD, CAMERAMATRIX, UNDISTORTPOINTS, TRIANGULATE.
```

