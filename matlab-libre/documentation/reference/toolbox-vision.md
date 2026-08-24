# Toolbox `vision`

```
% Computer Vision Toolbox — vision par ordinateur.
%
% Points d'intérêt et descripteurs
%   detectHarrisFeatures   - Coins de Harris
%   detectMinEigenFeatures - Coins de Shi et Tomasi
%   detectFASTFeatures     - Coins FAST
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
%   epipolarLine                 - Droites épipolaires
%   triangulate                  - Reconstruction par intersection de rayons
%   rotationVectorToMatrix       - Formule de Rodrigues
%   rotationMatrixToVector       - Axe et angle d'une rotation
%   generateCheckerboardPoints   - Coins d'un damier d'étalonnage
%   houghLines                   - Droites par transformée de Hough
%
% Stéréo et mouvement
%   stereoAnaglyph         - Anaglyphe rouge-cyan
%   disparityBM            - Disparité par appariement de blocs
%   opticalFlowLK          - Flot optique de Lucas et Kanade
%   opticalFlowHS          - Flot optique de Horn et Schunck
%   assignDetectionsToTracks - Appariement optimal, algorithme hongrois
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

## `insertShape`

```
INSERTSHAPE Dessine un rectangle ou une ligne dans une image.
  J = INSERTSHAPE(I,'rectangle',[x y w h]) trace le contour.
  J = INSERTSHAPE(I,'line',[x1 y1 x2 y2]) trace un segment.
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

## `matchFeatures`

```
MATCHFEATURES Appariement de descripteurs par plus proche voisin.
  PAIRES = MATCHFEATURES(D1,D2) rend les couples d'indices appariés. Le
  test du rapport des deux meilleures distances (0.7) élimine les
  appariements ambigus.
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
  [U,V] = OPTICALFLOWLK(I1,I2) rend les deux composantes du déplacement
  estimé en chaque pixel.
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

