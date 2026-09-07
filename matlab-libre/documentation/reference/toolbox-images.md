# Toolbox `images`

```
% Image Processing Toolbox — traitement d'images.
%
% Les images sont des matrices : un plan pour les niveaux de gris, trois
% pour la couleur. Les doubles vivent dans [0,1], les uint8 dans [0,255],
% comme dans MATLAB.
%
% Lecture, écriture, affichage
%   imread, imwrite, imshow
%
% Conversions
%   im2double, im2uint8, im2gray, rgb2gray, gray2rgb
%   rgb2hsv, hsv2rgb, rgb2ycbcr, ycbcr2rgb
%   imcomplement - Négatif
%
% Arithmétique
%   imadd, imsubtract, immultiply, imdivide, imabsdiff, imlincomb
%
% Géométrie
%   imresize, imrotate, imcrop, imtranslate, padarray
%
% Filtrage
%   imfilter    - Filtrage linéaire, avec choix du remplissage des bords
%   fspecial    - Noyaux usuels
%   imgaussfilt - Flou gaussien
%   imboxfilt   - Moyenne sur un carré
%   imsharpen   - Accentuation par masque flou
%   medfilt2    - Filtre médian
%   ordfilt2    - Filtre de rang
%   stdfilt, rangefilt, entropyfilt - Statistiques locales
%
% Gradient et contours
%   imgradientxy, imgradient - Gradient, amplitude et direction
%   edge        - Détection de contours : Sobel, Prewitt, Roberts,
%                 laplacien du gaussien, et Canny à double seuil
%   hough       - Transformée de Hough d'une image binaire
%   houghpeaks  - Pics de l'accumulateur
%   houghlines  - Segments de droite d'après les pics
%   imfindcircles - Cercles, par la transformée de Hough circulaire
%   normxcorr2  - Corrélation croisée normalisée
%
% Histogramme et contraste
%   imhist, histeq, imadjust, stretchlim
%   adapthisteq - Égalisation adaptative à contraste limité
%   mat2gray    - Remise dans [0,1]
%   graythresh, imbinarize, multithresh, imquantize
%   im2bw       - Seuillage, ancienne forme d'IMBINARIZE
%
% Régions
%   poly2mask   - Masque des points intérieurs à un polygone
%   roicolor    - Sélection par intensité
%   roifilt2    - Filtrage à l'intérieur d'une région
%   activecontour - Segmentation par contour actif (Chan-Vese)
%   impixel     - Valeurs de pixels choisis
%   imoverlay   - Pose un masque coloré sur une image
%   montage     - Plusieurs images en mosaïque
%
% Morphologie
%   strel       - Élément structurant
%   imdilate, imerode, imopen, imclose
%   imtophat, imbothat - Chapeaux haut et bas de forme
%   imfill      - Bouchage des trous
%   bwperim, bwarea, bweuler, bwdist
%   bwlabel, bwconncomp, regionprops, label2rgb
%
% Texture
%   graycomatrix, graycoprops - Cooccurrence et ses descripteurs
%
% Qualité
%   mean2, std2, corr2, immse, psnr, ssim
%
% Transformées
%   dct2, idct2 - Cosinus discrète bidimensionnelle
%
% Bruit
%   imnoise
%
% Espaces de couleur
%   rgb2lin, lin2rgb   - Correction gamma de sRGB, dans les deux sens
%   rgb2xyz, xyz2rgb   - Passage à l'espace XYZ de la CIE
%   xyz2lab, lab2xyz   - Passage de XYZ à L*a*b*
%   rgb2lab, lab2rgb   - Enchaînement des deux
%   rgb2ntsc, ntsc2rgb - Espace YIQ de la télévision
%   whitepoint         - Blancs de référence normalisés
%   imsplit            - Sépare les plans d'une image
%
% Images indexées
%   gray2ind, ind2gray, ind2rgb, rgb2ind, imapprox
%
% Reconstruction morphologique
%   imreconstruct      - Dilatation géodésique jusqu'à stabilité
%   imregionalmax, imregionalmin - Extrema régionaux
%   imhmax, imhmin     - Rabote les extrema de faible relief
%   imextendedmax, imextendedmin - Extrema d'au moins H
%   imimposemin        - Impose les minima, pour la ligne de partage
%   imclearborder      - Retire ce qui touche le bord
%   conndef            - Tableau de connexité par défaut
%
% Composantes connexes
%   bwlabeln           - Étiquetage, connexité quelconque
%   bwareaopen, bwareafilt, bwpropfilt, bwselect
%   bwhitmiss          - Transformation tout ou rien
%   bwconvhull         - Enveloppe convexe des objets
%
% Squelettes et contours
%   bwmorph            - Vingt opérations sur images binaires
%   bwskel             - Squelette par amincissement
%   bwboundaries       - Contours des objets et de leurs trous
%   bwtraceboundary    - Suivi de contour de Moore
%   watershed          - Ligne de partage des eaux
%
% Découpage en blocs
%   im2col, col2im     - Blocs vers colonnes et retour
%   nlfilter, colfilt, blockproc - Filtres définis par une fonction
%   checkerboard       - Damier d'essai
%   impyramid          - Étage de pyramide gaussienne
%
% Fonctions internes (absentes de MATLAB)
%   morphologie, matriceRVBversXYZ, appliquerMatriceCouleur,
%   adapterBlanc, voisinageConnexite
```

## `activecontour`

```
ACTIVECONTOUR Segmentation par contour actif.
  BW = ACTIVECONTOUR(I,MASQUE) fait évoluer le contour initial MASQUE
  jusqu'à épouser la région de l'image. Le contour se déplace de
  lui-même vers un équilibre entre deux exigences : que l'intérieur et
  l'extérieur soient chacun homogènes, et que le contour reste court.

  BW = ACTIVECONTOUR(I,MASQUE,N) fait N itérations (100 par défaut).
  BW = ACTIVECONTOUR(I,MASQUE,N,'edge') attire au contraire le contour
  vers les forts gradients ; 'Chan-Vese' (défaut) ne regarde que les
  moyennes des deux régions, ce qui marche même sur une image floue,
  où il n'y a pas de contour net à suivre.

  ACTIVECONTOUR(...,'SmoothFactor',S) pèse la longueur du contour
  (0,5 par défaut) ; 'ContractionBias',B le fait se resserrer quand B
  est positif, s'étendre quand il est négatif.

  Exemple :
     I = zeros(80, 80);
     [X, Y] = meshgrid(1:80, 1:80);
     I((X - 40) .^ 2 + (Y - 40) .^ 2 < 400) = 1;
     masque = false(80, 80);
     masque(30:50, 30:50) = true;
     BW = activecontour(I, masque, 150);

  Voir aussi IMSEGKMEANS, IMBINARIZE, WATERSHED, BWBOUNDARIES, EDGE.
```

## `adapterBlanc`

```
ADAPTERBLANC Adaptation chromatique de von Kries, en coordonnées XYZ.
  Chaque axe est mis à l'échelle du rapport des blancs. C'est la forme
  la plus simple de l'adaptation, celle que MATLAB emploie par défaut
  pour les conversions entre illuminants.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.

  Exemple :
     D65 = [0.95047 1 1.08883];
     A = [1.0985 1 0.3558];
     max(abs(adapterBlanc(D65, D65, A) - A)) < 1e-9   % le blanc source devient le blanc cible
```

## `adapthisteq`

```
ADAPTHISTEQ Égalisation d'histogramme adaptative à contraste limité.
  J = ADAPTHISTEQ(I) découpe l'image en tuiles, égalise l'histogramme
  de chacune, puis interpole entre les tuiles voisines pour effacer
  les coutures. Contrairement à HISTEQ, qui traite l'image entière,
  elle révèle le détail des zones sombres sans écraser les zones
  claires.

  L'histogramme de chaque tuile est écrêté avant égalisation — c'est
  le « contraste limité » —, faute de quoi le bruit d'une zone uniforme
  serait amplifié jusqu'à devenir visible.

  ADAPTHISTEQ(...,'NumTiles',[L C]) donne le découpage (8 par 8 par
  défaut), 'ClipLimit',C l'écrêtage entre 0 et 1 (0,01 par défaut),
  'NBins',N le nombre de niveaux (256), 'Range','original' garde
  l'étendue de l'image au lieu de l'étaler.

  ADAPTHISTEQ(...,'Distribution',D) choisit la forme visée par
  l'histogramme de sortie : 'uniform' (défaut), 'rayleigh' ou
  'exponential', et 'Alpha',A en règle le paramètre (0,4 par défaut).
  L'uniforme aplatit l'histogramme ; la loi de Rayleigh lui donne une
  forme en cloche, ce qui relève les tons sombres ; l'exponentielle
  les concentre vers le bas et assombrit l'image.

  Exemple :
     I = mat2gray(peaks(128));
     J = adapthisteq(I, 'ClipLimit', 0.02);

  Voir aussi HISTEQ, IMADJUST, IMHIST, IMLOCALBRIGHTEN, STRETCHLIM.
```

## `appliquerMatriceCouleur`

```
APPLIQUERMATRICECOULEUR Combine linéairement les trois plans d'une image.
  Accepte une image H x L x 3 ou une liste N x 3 de couleurs, et rend
  la même forme.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.

  Exemple :
     M = matriceRVBversXYZ();
     sortie = appliquerMatriceCouleur([1 0 0; 0 1 0], M);
     size(sortie)                % 2 3 : la forme de l'entree est gardee
```

## `blockproc`

```
BLOCKPROC Applique une fonction bloc par bloc.
  B = BLOCKPROC(A,[M N],FUN) découpe A en blocs disjoints de M x N et
  applique FUN à chacun. FUN reçoit une structure dont le champ `data`
  porte le bloc, comme dans MATLAB.

  Exemple :
     blockproc(magic(4), [2 2], @(b) mean(b.data(:)) * ones(2))
```

## `bwarea`

```
BWAREA Aire d'une région binaire, en pixels.
  A = BWAREA(BW) rend l'aire des pixels vrais, pondérée pour mieux
  estimer l'aire de la forme continue sous-jacente qu'un simple compte.

  Un simple compte surestime les diagonales : un segment en escalier
  compte autant de pixels qu'un segment droit deux fois plus court. La
  pondération corrige cela en regardant les motifs de deux par deux.

  Exemple :
     bw = false(10); bw(3:7, 3:7) = true;
     bwarea(bw)                      % proche de 25

  Voir aussi BWLABEL, REGIONPROPS, IMBINARIZE.
```

## `bwareafilt`

```
BWAREAFILT Ne garde que les composantes de l'aire voulue.
  BWAREAFILT(BW,N) garde les N plus grandes ; BWAREAFILT(BW,[MIN MAX])
  garde celles dont l'aire est dans l'intervalle.

  Exemple :
     bw = false(20, 20);
     bw(3:6, 3:6) = true;        % un carre de 16 pixels
     bw(10:18, 10:18) = true;    % un autre de 81
     garde = bwareafilt(bw, 1);
     sum(garde(:))               % 81 : seule la plus grande reste
```

## `bwareaopen`

```
BWAREAOPEN Retire les composantes de moins de P pixels.

  Exemple :
     bw = false(5); bw(2,2) = true; bw(4:5,4:5) = true;
     bwareaopen(bw, 2)   % le point isolé disparaît
```

## `bwboundaries`

```
BWBOUNDARIES Contours des objets d'une image binaire.
  B = BWBOUNDARIES(BW) rend un tableau de cellules ; chaque cellule est
  une liste de couples [ligne colonne] parcourant le contour d'un
  objet, le premier point étant répété à la fin.

  [B,L,N,A] = BWBOUNDARIES(...) rend aussi l'image étiquetée, le nombre
  d'objets et la matrice d'adjacence entre objets et trous.

  BWBOUNDARIES(BW,CONN,'noholes') ignore les trous.

  Exemple :
     bw = false(5); bw(2:4, 2:4) = true;
     b = bwboundaries(bw);   % un contour de huit points plus le retour
```

## `bwconncomp`

```
BWCONNCOMP Composantes connexes d'une image binaire.
  CC = BWCONNCOMP(BW,CONNEXITE) rend une structure aux champs
  Connectivity, ImageSize, NumObjects et PixelIdxList — la même que
  celle de MATLAB.

  Exemple :
     bw = false(20, 20);
     bw(3:6, 3:6) = true;        % un carre de 16 pixels
     bw(10:18, 10:18) = true;    % un autre de 81
     cc = bwconncomp(bw);
     cc.NumObjects               % 2
```

## `bwconvhull`

```
BWCONVHULL Enveloppe convexe des objets d'une image binaire.
  BWCONVHULL(BW) rend l'enveloppe de l'ensemble des pixels allumés.
  BWCONVHULL(BW,'objects') traite chaque composante à part.

  Exemple :
     bw = false(20, 20);
     bw(5, 5) = true; bw(15, 5) = true; bw(10, 15) = true;
     sum(sum(bwconvhull(bw))) > 3        % l'enveloppe remplit le triangle
```

## `bwdist`

```
BWDIST Distance euclidienne au pixel vrai le plus proche.
  D = BWDIST(BW) rend, pour chaque pixel, la distance au plus proche
  pixel vrai. [D,IDX] = BWDIST(BW) rend aussi l'indice linéaire de ce
  pixel.

  Exemple :
     a = false(3); a(2,2) = true; bwdist(a)(1,1)   % sqrt(2)
```

## `bweuler`

```
BWEULER Nombre d'Euler : régions moins trous.
  E = BWEULER(BW,8) par défaut.

  Exemple :
     bw = false(20, 20);
     bw(5:15, 5:15) = true;
     bw(8:12, 8:12) = false;     % un carre troue
     bweuler(bw)                 % 0 : un objet moins un trou
```

## `bwhitmiss`

```
BWHITMISS Transformation tout ou rien.
  BWHITMISS(BW,SE1,SE2) garde les pixels dont le voisinage contient
  SE1 dans l'objet et SE2 dans le fond. Avec un seul élément à trois
  valeurs, 1 impose l'objet, -1 le fond, 0 laisse libre.

  Exemple :
     bw = false(10, 10);
     bw(4:6, 4:6) = true;
     sortie = bwhitmiss(bw, ones(3), zeros(3));
     sum(sortie(:))              % 1 : le seul centre de carre plein
```

## `bwlabel`

```
BWLABEL Étiquetage des composantes connexes d'une image binaire.
  [L,N] = BWLABEL(BW) numérote les régions de pixels vrais.
  CONNEXITE vaut 4 ou 8 (8 par défaut).

  Exemple :
     bw = false(20, 20);
     bw(3:6, 3:6) = true;        % un carre de 16 pixels
     bw(10:18, 10:18) = true;    % un autre de 81
     [etiquettes, n] = bwlabel(bw);
     n                           % 2 : deux composantes connexes
```

## `bwlabeln`

```
BWLABELN Étiquetage des composantes connexes, connexité quelconque.
  Sur une image bidimensionnelle, CONNEXITE peut valoir 4, 8 ou un
  tableau logique 3 x 3.

  Exemple :
     bw = false(20, 20);
     bw(3:6, 3:6) = true;        % un carre de 16 pixels
     bw(10:18, 10:18) = true;    % un autre de 81
     [etiquettes, n] = bwlabeln(bw);
     n                           % 2
```

## `bwmorph`

```
BWMORPH Opérations morphologiques sur une image binaire.
  BW2 = BWMORPH(BW,OPERATION) applique une fois l'opération nommée ;
  BWMORPH(BW,OPERATION,N) la répète N fois, ou jusqu'à stabilité si N
  vaut Inf.

  Opérations reconnues : 'clean' (retire les pixels isolés), 'fill'
  (bouche les trous d'un pixel), 'bridge' (relie deux pixels séparés
  par un seul), 'remove' (ne garde que le bord), 'majority' (garde le
  pixel si cinq voisins sur neuf sont allumés), 'erode', 'dilate',
  'open', 'close', 'diag' (comble les liaisons diagonales),
  'endpoints', 'branchpoints', 'thin', 'skel', 'spur', 'thicken',
  'hbreak', 'tophat', 'bothat'.

  Exemple :
     bw = false(5); bw(3,3) = true;
     bwmorph(bw, 'clean')   % le pixel isolé disparaît
```

## `bwperim`

```
BWPERIM Contour d'une région binaire.
  P = BWPERIM(BW) garde les pixels vrais qui touchent au moins un pixel
  faux dans le voisinage à quatre voisins.

  Exemple :
     sum(sum(bwperim(true(3))))   % 8 : tout sauf le centre
```

## `bwpropfilt`

```
BWPROPFILT Ne garde que les composantes classées par une propriété.
  BWPROPFILT(BW,'Area',N) équivaut à BWAREAFILT. Toute propriété
  scalaire rendue par REGIONPROPS convient : 'Perimeter',
  'EquivDiameter', 'Eccentricity'…

  Exemple :
     bw = false(20, 20);
     bw(3:6, 3:6) = true;        % un carre de 16 pixels
     bw(10:18, 10:18) = true;    % un autre de 81
     garde = bwpropfilt(bw, 'Area', 1);
     sum(garde(:))               % 81 : la plus grande aire
```

## `bwselect`

```
BWSELECT Garde les objets qui contiennent les points désignés.
  BWSELECT(BW,C,R) où C sont les colonnes et R les lignes des points,
  dans cet ordre — c'est la convention de MATLAB.

  Exemple :
     bw = false(20, 20);
     bw(3:6, 3:6) = true;        % un carre de 16 pixels
     bw(10:18, 10:18) = true;    % un autre de 81
     [sortie, indices] = bwselect(bw, 4, 4);
     sum(sortie(:))              % 16 : la composante qui contient (4,4)
```

## `bwskel`

```
BWSKEL Squelette d'une image binaire.
  Amincissement de Zhang et Suen jusqu'à stabilité : il ne reste qu'un
  trait d'un pixel d'épaisseur, de même topologie que l'objet.

  BWSKEL(...,'MinBranchLength',L) élague ensuite les barbes de moins de
  L pixels.

  Exemple :
     bw = false(9); bw(4:6, 2:8) = true;
     s = bwskel(bw);   % un segment horizontal
```

## `bwtraceboundary`

```
BWTRACEBOUNDARY Suit le contour d'un objet à partir d'un point.
  C = BWTRACEBOUNDARY(BW,P,DIR) part du pixel P = [ligne colonne] en
  cherchant d'abord dans la direction DIR ('N', 'NE', 'E'…) et suit le
  bord de l'objet jusqu'à revenir au départ.

  L'algorithme est celui de Moore : on tourne autour du pixel courant à
  partir du voisin d'où l'on vient, et l'on saute sur le premier pixel
  allumé rencontré.

  Exemple :
     bw = false(10, 10);
     bw(3:7, 3:7) = true;
     c = bwtraceboundary(bw, [3 3], 'E');
     size(c, 2)                  % 2 : ligne et colonne par point
```

## `checkerboard`

```
CHECKERBOARD Damier d'essai pour les transformations géométriques.
  I = CHECKERBOARD(N,P,Q) rend un damier dont chaque carreau fait N
  pixels de côté, avec P rangées et Q colonnes de paires de carreaux.
  La moitié droite est plus claire, ce qui permet de repérer une
  symétrie.

  Exemple :
     imshow(checkerboard(10));
```

## `col2im`

```
COL2IM Réassemble une image à partir de colonnes de blocs.
  Réciproque d'IM2COL pour le découpage disjoint ; pour le découpage
  glissant, chaque colonne fournit un pixel, comme dans MATLAB.

  Exemple :
     colonnes = im2col(magic(4), [2 2], 'distinct');
     max(max(abs(col2im(colonnes, [2 2], [4 4], 'distinct') - magic(4))))   % 0
```

## `colfilt`

```
COLFILT Filtre par colonnes : la fonction voit tous les blocs à la fois.
  B = COLFILT(A,[M N],'sliding',FUN) passe à FUN une matrice dont
  chaque colonne est un voisinage, et attend une ligne de résultats.
  C'est la version rapide de NLFILTER.

  Exemple :
     colfilt(magic(4), [3 3], 'sliding', @max)
```

## `conndef`

```
CONNDEF Tableau de connexité par défaut.
  C = CONNDEF(N,TYPE) où TYPE vaut 'minimal' (les voisins qui partagent
  une face) ou 'maximal' (tous les voisins immédiats).

  Exemple :
     conndef(2, 'minimal')   % [0 1 0; 1 1 1; 0 1 0]
```

## `corr2`

```
CORR2 Coefficient de corrélation entre deux matrices de même taille.
  Exemple :
     corr2(magic(4), magic(4))   % 1
```

## `dct2`

```
DCT2 Transformée en cosinus discrète bidimensionnelle.
  Y = DCT2(X) applique DCT aux colonnes puis aux lignes.

  Exemple :
     x = magic(4);
     max(max(abs(idct2(dct2(x)) - x))) < 1e-10   % la transformee est orthonormee
```

## `edge`

```
EDGE Détection de contours.
  C = EDGE(X) applique Sobel avec un seuil automatique.
  C = EDGE(X,'sobel'|'prewitt'|'roberts'|'log'|'canny',SEUIL) choisit
  la méthode.

  La méthode de Canny est celle qui donne des contours d'un pixel
  d'épaisseur : elle lisse l'image, cherche le maximum du gradient dans
  la direction où il pointe — les autres points sont écartés —, puis
  suit les contours par un double seuil, ce qui garde les traits
  faibles rattachés à un trait fort.

  C = EDGE(X,'canny',[BAS HAUT]) donne les deux seuils, entre 0 et 1.
  C = EDGE(X,'canny',SEUIL,SIGMA) règle le lissage (racine de 2 par
  défaut).

  [C,SEUIL] = EDGE(...) rend aussi le seuil employé.

  Exemple :
     I = mat2gray(peaks(100));
     C = edge(I, 'canny');

  Voir aussi IMGRADIENT, FSPECIAL, IMFILTER, HOUGH, BWMORPH.
```

## `entropyfilt`

```
ENTROPYFILT Entropie locale, en bits.
  L'histogramme est calculé sur 256 niveaux, comme dans MATLAB.

  Exemple :
     rng(1);
     r = entropyfilt(rand(20));
     all(r(:) >= 0)              % 1 : une entropie est positive
```

## `fspecial`

```
FSPECIAL Noyaux de filtrage usuels.
  H = FSPECIAL('average',N)      moyenne N x N
  H = FSPECIAL('gaussian',N,SIG) gaussienne
  H = FSPECIAL('sobel')          gradient vertical
  H = FSPECIAL('prewitt')        gradient vertical
  H = FSPECIAL('laplacian')      laplacien
  H = FSPECIAL('log',N,SIG)      laplacien de gaussienne

  Exemple :
     h = fspecial('gaussian', 5, 1);
     abs(sum(h(:)) - 1) < 1e-12  % un lissage conserve la moyenne
     abs(sum(sum(fspecial('laplacian')))) < 1e-12   % un derivateur annule le continu
```

## `gray2ind`

```
GRAY2IND Image en niveaux de gris vers image indexée.
  [X,MAP] = GRAY2IND(I,N) quantifie I sur N niveaux ; N vaut 64 par
  défaut. Les indices commencent à zéro, comme dans MATLAB pour les
  entiers non signés.

  Exemple :
     [x, map] = gray2ind([0 0.5 1], 4);   % x = [0 1 3]
```

## `gray2rgb`

```
GRAY2RGB Réplique une image en niveaux de gris sur trois canaux.
  RGB = GRAY2RGB(G) recopie le plan de gris sur les trois canaux.

  L'image obtenue est toujours grise : la conversion n'invente aucune
  couleur, elle change seulement la représentation. Elle sert à
  superposer un tracé en couleur sur un fond en gris, ce qu'un tableau à
  deux dimensions ne permet pas.

  Exemple :
     rgb = gray2rgb(rand(8));
     size(rgb)                       % 8 8 3
     max(max(abs(rgb(:,:,1) - rgb(:,:,3))))    % 0 : toujours du gris

  Voir aussi RGB2GRAY, IND2RGB, IM2DOUBLE.
```

## `graycomatrix`

```
GRAYCOMATRIX Matrice de cooccurrence des niveaux de gris.
  GLCM = GRAYCOMATRIX(I) compte les couples de pixels voisins à droite,
  après quantification sur 8 niveaux. Options : 'NumLevels',
  'GrayLimits', 'Offset' (matrice de décalages [dl dc], une ligne par
  décalage).

  Exemple :
     graycomatrix([1 1 1; 1 1 1; 1 1 1], 'NumLevels', 2)
```

## `graycoprops`

```
GRAYCOPROPS Descripteurs d'une matrice de cooccurrence.
  S = GRAYCOPROPS(GLCM) rend Contrast, Correlation, Energy et
  Homogeneity, telles que les définit la documentation MathWorks.

  Exemple :
     glcm = graycomatrix(uint8(magic(8)));
     s = graycoprops(glcm, {'Contrast', 'Energy'});
     s.Energy > 0                % 1
```

## `graythresh`

```
GRAYTHRESH Seuil global par la méthode d'Otsu.
  SEUIL = GRAYTHRESH(X) maximise la variance interclasse.

  Exemple :
     x = [zeros(50, 1); ones(50, 1)];
     seuil = graythresh(x);
     seuil > 0 && seuil < 1      % Otsu separe les deux modes
```

## `histeq`

```
HISTEQ Égalisation d'histogramme.
  Y = HISTEQ(X,N) étale les niveaux de gris pour que leur histogramme
  soit à peu près plat sur N casiers, 64 par défaut.

  Le principe : appliquer à l'image sa propre fonction de répartition
  cumulée. Une image dont tous les pixels sont entassés dans une plage
  étroite s'étale alors sur toute la dynamique, et son contraste
  apparent augmente beaucoup.

  Le procédé est brutal : il amplifie le bruit des zones uniformes
  autant que le signal des zones utiles, et il change les rapports de
  luminance. L'égalisation locale — CLAHE — corrige le premier défaut,
  pas le second.

  Exemple :
     terne = 0.4 + 0.2 * rand(64);
     clair = histeq(terne);
     std(clair(:)) > std(terne(:))   % true : le contraste augmente

  Voir aussi IMADJUST, IMHIST, IMBINARIZE.
```

## `hough`

```
HOUGH Transformée de Hough d'une image binaire.
  [H,THETA,RHO] = HOUGH(BW) rend l'accumulateur de Hough : chaque point
  allumé de BW vote pour toutes les droites qui passent par lui, et
  H(i,j) compte les votes de la droite d'angle THETA(j) et de distance
  RHO(i). Une droite de l'image apparaît alors comme un pic.

  Une droite s'écrit x cos(theta) + y sin(theta) = rho, ce qui la
  décrit sans cas particulier — la forme y = ax+b ne sait pas dire
  « verticale ».

  HOUGH(...,'Theta',T) donne les angles en degrés (-90 à 89 par pas
  d'un degré par défaut), 'RhoResolution',R le pas des distances.

  Exemple :
     BW = false(50, 50);
     BW(20, 5:45) = true;                % une droite horizontale
     [H, theta, rho] = hough(BW);
     pics = houghpeaks(H, 1);

  Voir aussi HOUGHPEAKS, HOUGHLINES, EDGE, IMFINDCIRCLES, RADON.
```

## `houghlines`

```
HOUGHLINES Segments de droite d'après les pics de Hough.
  DROITES = HOUGHLINES(BW,THETA,RHO,PICS) rend, pour chaque pic, les
  segments effectivement présents dans l'image : les points alignés
  sont regroupés, les trous courts comblés, et les segments trop courts
  écartés.

  Chaque élément porte point1, point2, theta et rho. Les points sont
  donnés en [x y], c'est-à-dire [colonne ligne].

  HOUGHLINES(...,'FillGap',G) comble les trous de moins de G pixels
  (20 par défaut), 'MinLength',L écarte les segments plus courts que L
  (40 par défaut).

  Exemple :
     BW = false(60, 60);
     BW(20, 5:55) = true;                 % une droite horizontale
     [H, theta, rho] = hough(BW);
     pics = houghpeaks(H, 3);
     droites = houghlines(BW, theta, rho, pics, 'MinLength', 10);

  Voir aussi HOUGH, HOUGHPEAKS, EDGE, REGIONPROPS.
```

## `houghpeaks`

```
HOUGHPEAKS Pics de l'accumulateur de Hough.
  PICS = HOUGHPEAKS(H,N) rend au plus N pics, une ligne par pic donnant
  sa ligne et sa colonne dans H. Après chaque pic retenu, son voisinage
  est mis à zéro : sans cela, un même pic large serait compté
  plusieurs fois.

  HOUGHPEAKS(...,'Threshold',T) ignore les pics sous T (la moitié du
  maximum par défaut), 'NHoodSize',[L C] donne la taille du voisinage
  effacé.

  Exemple :
     BW = false(60, 60);
     BW(20, 5:55) = true;
     [H, theta, rho] = hough(BW);
     pics = houghpeaks(H, 3);
     size(pics, 2)        % 2 : une ligne et une colonne par pic

  Voir aussi HOUGH, HOUGHLINES, IMREGIONALMAX.
```

## `hsv2rgb`

```
HSV2RGB Teinte, saturation, valeur vers RVB.
  R = HSV2RGB(IMAGE) où IMAGE est MxNx3, ou HSV2RGB(CARTE) où CARTE
  est une carte de couleurs Mx3. La sortie garde la forme de l'entrée.

  Exemple :
     max(abs(hsv2rgb([0 1 1]) - [1 0 0])) < 1e-12   % teinte nulle : du rouge pur
     max(abs(hsv2rgb([0 0 0.5]) - [0.5 0.5 0.5])) < 1e-12   % saturation nulle : du gris
```

## `idct2`

```
IDCT2 Transformée en cosinus discrète inverse bidimensionnelle.
  X = IDCT2(Y) reconstruit l'image à partir de ses coefficients.

  La DCT est ce qui fait JPEG : elle concentre l'énergie d'un bloc
  d'image dans quelques coefficients de basse fréquence, et jeter les
  autres se voit peu. IDCT2 refait le chemin inverse.

  L'aller-retour est exact à la précision machine, tant qu'on ne jette
  rien.

  Exemple :
     image = magic(8);
     max(max(abs(idct2(dct2(image)) - image)))    % ~1e-13

  Voir aussi DCT2, FFT2, IMWRITE.
```

## `im2bw`

```
IM2BW Convertit une image en noir et blanc par seuillage.
  BW = IM2BW(I,SEUIL) rend une image binaire : vrai là où I dépasse
  SEUIL, qui s'exprime entre 0 et 1 quelle que soit la classe de I.
  BW = IM2BW(I) emploie le seuil d'Otsu, que rend GRAYTHRESH.
  BW = IM2BW(X,CARTE,SEUIL) convertit d'abord une image indexée.

  Cette fonction est l'ancienne forme ; IMBINARIZE la remplace depuis
  R2016a et offre le seuillage adaptatif.

  Exemple :
     BW = im2bw(mat2gray(magic(8)), 0.5);

  Voir aussi IMBINARIZE, GRAYTHRESH, MULTITHRESH, IMQUANTIZE.
```

## `im2col`

```
IM2COL Réarrange les blocs d'une image en colonnes.
  IM2COL(A,[M N],'distinct') découpe l'image en blocs disjoints ;
  'sliding' (par défaut) prend tous les blocs glissants.

  Exemple :
     im2col(magic(4), [2 2], 'distinct')   % quatre colonnes de quatre
```

## `im2double`

```
IM2DOUBLE Convertit une image en double dans [0,1].
  Y = IM2DOUBLE(X) ramène une image entière sur l'intervalle [0,1] en
  divisant par la valeur maximale de son type — 255 pour uint8, 65535
  pour uint16. Une image déjà flottante est rendue telle quelle.

  Toute la boîte à outils travaille en flottant : c'est ce qui évite les
  dépassements et les troncatures au milieu d'un calcul. IM2UINT8 refait
  le chemin inverse au moment d'écrire.

  Exemple :
     im2double(uint8([0 128 255]))   % [0 0.502 1]
     im2double([0.2 0.8])            % inchange

  Voir aussi IM2UINT8, MAT2GRAY, IMREAD.
```

## `im2gray`

```
IM2GRAY Rend une image en niveaux de gris, quelle que soit l'entrée.
  Une image déjà en niveaux de gris ressort inchangée.

  Exemple :
     max(abs(im2gray(reshape([0.2 0.4 0.6], 1, 1, 3)) - rgb2gray(reshape([0.2 0.4 0.6], 1, 1, 3)))) < 1e-12
     isequal(im2gray(rand(4)), im2gray(rand(4)) * 1)   % une image grise passe telle quelle
```

## `im2uint8`

```
IM2UINT8 Convertit une image en uint8 (0 à 255).
  Y = IM2UINT8(X) multiplie une image flottante par 255 et arrondit.
  Ce qui sort de [0,1] est écrêté, non mis à l'échelle.

  La conversion perd de l'information : deux valeurs distantes de moins
  de 1/255 deviennent identiques. C'est pourquoi on ne convertit qu'à la
  fin, pour écrire ou pour afficher.

  Exemple :
     im2uint8([0 0.5 1])             % [0 128 255]
     im2uint8(im2double(uint8(42)))  % 42 : l'aller-retour est exact

  Voir aussi IM2DOUBLE, IMWRITE.
```

## `imabsdiff`

```
IMABSDIFF Différence absolue de deux images, sans dépassement.
  Z = IMABSDIFF(X,Y) rend la valeur absolue de la différence : elle ne
  sature jamais, contrairement à IMSUBTRACT, puisque le résultat tient
  toujours dans le type. C'est ce qui en fait l'outil de la détection de
  mouvement entre deux images.

  Les opérations arithmétiques sur images saturent au lieu de déborder :
  sur des entiers, 200 + 100 vaut 255 et non 44. C'est ce qui les
  distingue de l'arithmétique ordinaire, et c'est presque toujours ce
  qu'on veut d'une image.

  Exemple :
     imabsdiff(uint8(50), uint8(100))    % 50, dans les deux sens

  Voir aussi IMSUBTRACT, IMMSE, IMADD.
```

## `imadd`

```
IMADD Somme de deux images, avec saturation pour les entiers.
  Z = IMADD(X,Y) additionne deux images de même taille, ou une image et
  une constante.

  Les opérations arithmétiques sur images saturent au lieu de déborder :
  sur des entiers, 200 + 100 vaut 255 et non 44. C'est ce qui les
  distingue de l'arithmétique ordinaire, et c'est presque toujours ce
  qu'on veut d'une image.

  Exemple :
     imadd(uint8(200), uint8(100))   % 255, non 44

  Voir aussi IMSUBTRACT, IMMULTIPLY, IMDIVIDE, IMABSDIFF.
```

## `imadjust`

```
IMADJUST Étirement de contraste.
  Y = IMADJUST(X,[BAS HAUT],[NBAS NHAUT],GAMMA) applique la transformation
  affine par morceaux suivie de la correction gamma.

  Exemple :
     x = [0.2 0.5 0.8];
     y = imadjust(x, [0.2 0.8], [0 1]);
     [y(1) y(end)]               % 0 et 1 : les bornes s'etirent
```

## `imapprox`

```
IMAPPROX Réduit le nombre de couleurs d'une image indexée.
  [Y,NEWMAP] = IMAPPROX(X,MAP,N) rend une image à N couleurs.

  Exemple :
     rng(1);
     [i, c] = imapprox(randi(64, 10, 10), rand(64, 3), 8);
     size(c, 1)                  % 8 : la palette est reduite
```

## `imbinarize`

```
IMBINARIZE Seuillage d'une image en niveaux de gris.
  BW = IMBINARIZE(X) seuille par la méthode d'Otsu, qui choisit le seuil
  maximisant la variance entre les deux classes.
  BW = IMBINARIZE(X,SEUIL) impose le seuil.

  Otsu ne suppose rien de l'image sinon que son histogramme est
  bimodal : il cherche la séparation qui rend les deux groupes les plus
  distincts possible. Sur une image dont l'éclairage varie, il échoue —
  le seuil global ne convient alors nulle part, et il faut seuiller
  localement.

  Exemple :
     bw = imbinarize([0.1 0.2; 0.8 0.9]);
     sum(bw(:))                      % 2 : les deux clairs

  Voir aussi HISTEQ, IMHIST, BWAREA, IMADJUST.
```

## `imbothat`

```
IMBOTHAT Chapeau bas de forme : la fermeture moins l'image.
  Fait ressortir les détails sombres.

  Exemple :
     bw = false(20, 20);
     bw(5:15, 5:15) = true;
     bw(9:11, 9:11) = false;     % un trou
     sum(sum(imbothat(double(bw), ones(3)))) > 0   % le chapeau noir voit le trou
```

## `imboxfilt`

```
IMBOXFILT Filtre moyenneur, à noyau carré.
  R = IMBOXFILT(I,N) moyenne sur un carré de N points de côté ; N est
  impair. C'est le filtre le moins cher, et le plus flou.

  Exemple :
     r = imboxfilt(ones(10), 3);
     abs(r(5, 5) - 1) < 1e-12    % une moyenne d'uns vaut un
```

## `imclearborder`

```
IMCLEARBORDER Supprime les objets qui touchent le bord de l'image.
  La reconstruction part du bord : tout ce qu'elle atteint est retiré.

  Exemple :
     bw = false(5); bw(1,1) = true; bw(3,3) = true;
     imclearborder(bw)   % il ne reste que le point du centre
```

## `imclose`

```
IMCLOSE Fermeture morphologique : dilatation puis érosion.
  Y = IMCLOSE(X,ELEMENT) bouche les trous plus petits que l'élément
  structurant, puis rend aux formes leur taille.

  La fermeture est elle aussi idempotente, et duale de l'ouverture : la
  fermeture du complément est le complément de l'ouverture. Elle ne peut
  qu'ajouter — le résultat contient l'original.

  Exemple :
     troue = true(20); troue(10, 10) = false;
     imclose(troue, true(3))(10, 10)    % true : le trou est bouche

  Voir aussi IMOPEN, IMDILATE, IMERODE.
```

## `imcomplement`

```
IMCOMPLEMENT Négatif d'une image.
  Pour un double dans [0,1], c'est 1-X ; pour un uint8, 255-X ; pour un
  logique, la négation.

  Exemple :
     imcomplement([0 0.25 1])    % 1 0.75 0
     imcomplement(uint8([0 255]))    % 255 0
```

## `imcrop`

```
IMCROP Découpe un rectangle dans une image.
  Y = IMCROP(X,[XMIN YMIN LARGEUR HAUTEUR]) rend la partie de l'image
  comprise dans le rectangle. XMIN et YMIN sont la colonne et la ligne
  du coin supérieur gauche.

  La taille rendue est HAUTEUR+1 sur LARGEUR+1, non HAUTEUR sur
  LARGEUR : le rectangle décrit une étendue spatiale, du bord gauche du
  premier pixel au bord droit du dernier, et non un compte de pixels.
  C'est la convention de MATLAB, et elle surprend toujours.

  Un rectangle qui déborde est ramené dans l'image : la fonction ne
  complète pas, elle tronque.

  Exemple :
     image = reshape(1:100, 10, 10);
     size(imcrop(image, [3 2 3 4]))       % [5 4] : hauteur+1, largeur+1
     imcrop(image, [3 2 3 4])(1, 1)       % image(2, 3)

  Voir aussi IMRESIZE, IMROTATE, IMADJUST.
```

## `imdilate`

```
IMDILATE Dilatation morphologique.
  Y = IMDILATE(X,ELEMENT) remplace chaque pixel par le maximum de son
  voisinage, défini par l'élément structurant.

  La dilatation ne peut qu'agrandir : le résultat contient toujours
  l'original. Elle bouche les trous, relie ce qui est presque connexe,
  et grossit tout d'autant.

  Elle est duale de l'érosion par complémentation : dilater le
  complément revient à éroder puis complémenter. C'est ce qui permet de
  n'implanter qu'une des deux.

  Exemple :
     bw = false(9); bw(5, 5) = true;
     sum(sum(imdilate(bw, true(3))))    % 9 : un point devient un carre

  Voir aussi IMERODE, IMOPEN, IMCLOSE.
```

## `imdivide`

```
IMDIVIDE Quotient terme à terme de deux images.
  Z = IMDIVIDE(X,Y) divise terme à terme. La division par zéro rend la
  valeur maximale du type plutôt qu'un infini, qui n'a pas de sens dans
  une image entière.

  Les opérations arithmétiques sur images saturent au lieu de déborder :
  sur des entiers, 200 + 100 vaut 255 et non 44. C'est ce qui les
  distingue de l'arithmétique ordinaire, et c'est presque toujours ce
  qu'on veut d'une image.

  Exemple :
     imdivide(uint8(100), 2)         % 50

  Voir aussi IMMULTIPLY, IMADD, IMSUBTRACT.
```

## `imerode`

```
IMERODE Érosion morphologique.
  Y = IMERODE(X,ELEMENT) remplace chaque pixel par le minimum de son
  voisinage.

  L'érosion ne peut que rétrécir : le résultat est contenu dans
  l'original. Elle efface ce qui est plus petit que l'élément
  structurant, ce qui en fait un filtre de taille — c'est ainsi qu'on
  supprime le bruit poivre et sel sans toucher aux grandes formes.

  Éroder ce qu'on vient de dilater ne rend pas l'original en général :
  la composition est la fermeture, qui bouche les trous. C'est
  l'inverse pour l'ouverture.

  Exemple :
     bw = false(9); bw(5, 5) = true;
     sum(sum(imerode(bw, true(3))))     % 0 : un point isole disparait

  Voir aussi IMDILATE, IMOPEN, IMCLOSE.
```

## `imextendedmax`

```
IMEXTENDEDMAX Maxima étendus : les sommets d'au moins H de hauteur.
  BW = IMEXTENDEDMAX(X,H) marque les sommets qui dominent leur entourage
  d'au moins H. C'est le dual d'IMEXTENDEDMIN, sur la surface retournée.

  Exemple :
     relief = zeros(20); relief(5, 5) = 0.1; relief(15, 15) = 0.8;
     hauts = imextendedmax(relief, 0.5);
     hauts(15, 15) && ~hauts(5, 5)   % true

  Voir aussi IMEXTENDEDMIN, IMHMIN.
```

## `imextendedmin`

```
IMEXTENDEDMIN Minima étendus : les cuvettes d'au moins H de profondeur.
  BW = IMEXTENDEDMIN(X,H) marque les régions qui sont des minima
  régionaux de la surface une fois comblée de H.

  « Étendu » veut dire qu'un plateau entier est marqué, non un seul
  pixel : un minimum régional n'est pas forcément ponctuel, et ne
  retenir qu'un point y serait arbitraire.

  Exemple :
     relief = ones(20); relief(5, 5) = 0.9; relief(15, 15) = 0.2;
     profonds = imextendedmin(relief, 0.5);
     profonds(15, 15) && ~profonds(5, 5)     % true

  Voir aussi IMEXTENDEDMAX, IMHMIN, WATERSHED.
```

## `imfill`

```
IMFILL Bouche les trous d'une image binaire.
  R = IMFILL(BW,'holes') remplit les régions de faux qui ne touchent pas
  le bord. C'est une reconstruction morphologique depuis le bord, prise
  par complément.

  Exemple :
     a = true(5); a(3,3) = false; sum(sum(imfill(a,'holes')))   % 25
```

## `imfilter`

```
IMFILTER Filtrage linéaire d'une image.
  Y = IMFILTER(X,H) corrèle X avec le noyau H et rend une image de même
  taille. Les options, dans n'importe quel ordre :
     'conv' | 'corr'          convolution ou corrélation (défaut)
     'same' | 'full'          taille du résultat (défaut « same »)
     'replicate' | 'symmetric' | 'circular' | VALEUR   remplissage des
                              bords ; le défaut est zéro, comme MATLAB.

  Exemple :
     imfilter(ones(3), ones(3)/9, 'replicate')   % que des 1
```

## `imfindcircles`

```
IMFINDCIRCLES Cherche des cercles par la transformée de Hough.
  [CENTRES,RAYONS] = IMFINDCIRCLES(I,[RMIN RMAX]) cherche les cercles
  dont le rayon est compris entre RMIN et RMAX. CENTRES a une ligne par
  cercle, en [x y].

  [CENTRES,RAYONS] = IMFINDCIRCLES(I,R) cherche les cercles de rayon R.
  [CENTRES,RAYONS,FORCES] = IMFINDCIRCLES(...) rend la force de chaque
  détection, entre 0 et 1.

  Chaque point de contour vote pour les centres possibles — ceux qui
  sont à la distance R de lui —, et un cercle apparaît là où les votes
  se rassemblent.

  IMFINDCIRCLES(...,'Sensitivity',S) abaisse le seuil de détection
  quand S monte vers 1 (0,85 par défaut) ; 'EdgeThreshold',T règle le
  seuil du gradient ; 'ObjectPolarity','dark' cherche des objets
  sombres sur fond clair.

  Exemple :
     I = zeros(100, 100);
     [X, Y] = meshgrid(1:100, 1:100);
     I((X - 50) .^ 2 + (Y - 50) .^ 2 < 400) = 1;
     [centres, rayons] = imfindcircles(I, [15 25]);

  Voir aussi HOUGH, HOUGHPEAKS, EDGE, REGIONPROPS, VISCIRCLES.
```

## `imgaussfilt`

```
IMGAUSSFILT Lissage gaussien d'une image.
  Y = IMGAUSSFILT(X,SIGMA) convolue par une gaussienne d'écart type
  SIGMA, 0,5 par défaut.

  La gaussienne est le seul noyau séparable et isotrope à la fois : on
  peut donc filtrer les lignes puis les colonnes, ce qui coûte 2N au
  lieu de N carré. C'est aussi le seul qui ne crée aucun extremum
  nouveau — d'où son emploi comme base des espaces d'échelle.

  Le support effectif vaut environ trois écarts types de part et
  d'autre : au-delà, la gaussienne est négligeable.

  Exemple :
     lisse = imgaussfilt(rand(64), 2);
     std(lisse(:)) < std(rand(64))   % true : le lissage reduit l'ecart

  Voir aussi IMFILTER, FSPECIAL, MEDFILT2.
```

## `imgradient`

```
IMGRADIENT Amplitude et direction du gradient.
  [G,DIR] = IMGRADIENT(I) ou IMGRADIENT(GX,GY). La direction est en
  degrés, comptée depuis l'axe des x, positive dans le sens
  trigonométrique.

  Exemple :
     [amplitude, direction] = imgradient(repmat((1:10), 10, 1));
     abs(mean(mean(direction(2:9, 2:9)))) < 1e-9   % la pente est horizontale
```

## `imgradientxy`

```
IMGRADIENTXY Composantes horizontale et verticale du gradient.
  [GX,GY] = IMGRADIENTXY(I,METHODE) où METHODE vaut 'sobel' (défaut),
  'prewitt', 'central' ou 'intermediate'.

  Les conventions sont celles de MATLAB : GX est positif quand
  l'intensité croît vers la droite, GY quand elle croît vers le bas.
  Les bords sont répliqués.

  Exemple :
     [gx, gy] = imgradientxy([1 2 3; 4 5 6; 7 8 9]);
     gx(2, 2)   % 8, la réponse de Sobel sur une rampe horizontale
     gy(2, 2)   % 24, la rampe verticale est trois fois plus raide
```

## `imhist`

```
IMHIST Histogramme d'une image.
  [COMPTE,POSITIONS] = IMHIST(X,N) compte les pixels par casier de
  niveau, sur N casiers — 256 pour une image entière, 64 pour une image
  flottante par défaut.

  La somme des comptes est le nombre de pixels, toujours : c'est la
  vérification qui prouve qu'aucun n'a été perdu ni compté deux fois.

  La forme de l'histogramme dit ce qu'on peut faire de l'image : deux
  bosses séparées se seuillent, une seule bosse étroite se contraste,
  une bosse contre un bord est saturée et ne se rattrape pas.

  Exemple :
     [n, x] = imhist(uint8([0 0 128 255]));
     sum(n)                          % 4 : tous les pixels
     n(1)                            % 2 : deux pixels a zero

  Voir aussi HISTEQ, IMADJUST, IMBINARIZE.
```

## `imhmax`

```
IMHMAX Supprime les maxima de hauteur inférieure à H.
  La reconstruction de l'image depuis elle-même abaissée de H rabote
  les sommets peu marqués et laisse les autres.

  Exemple :
     imhmax([1 3 1], 5)   % [1 1 1] : le sommet ne fait que 2
```

## `imhmin`

```
IMHMIN Comble les minima de profondeur inférieure à H.
  Y = IMHMIN(X,H) relève les cuvettes dont la profondeur n'atteint pas
  H, et laisse les autres.

  C'est l'outil qui rend la ligne de partage des eaux utilisable : sans
  lui, chaque petite cuvette du bruit devient un bassin, et la
  segmentation éclate en centaines de régions. Combler les minima peu
  profonds fusionne ces bassins avant même de commencer.

  Exemple :
     relief = ones(20); relief(5, 5) = 0.9; relief(15, 15) = 0.2;
     comble = imhmin(relief, 0.5);
     comble(5, 5) == 1               % true : la cuvette peu marquee
     comble(15, 15) < 1              % true : la profonde reste

  Voir aussi IMEXTENDEDMIN, IMEXTENDEDMAX, WATERSHED.
```

## `imimposemin`

```
IMIMPOSEMIN Force les minima régionaux à se trouver là où on le dit.
  Sert à contrôler la ligne de partage des eaux : sans cela, chaque
  petite cuvette du relief donne un bassin.

  La construction est celle de Soille : on creuse à moins l'infini là
  où sont les marqueurs, on remonte tout le reste d'un cran, et on
  reconstruit par en dessous. Les seuls minima qui survivent sont ceux
  qu'on a imposés.

  Exemple :
     relief = [3 3 3; 3 1 3; 3 3 3];
     m = false(3); m(1,1) = true;
     imregionalmin(imimposemin(relief, m))   % le seul minimum est en (1,1)
```

## `imlincomb`

```
IMLINCOMB Combinaison linéaire d'images.
  R = IMLINCOMB(K1,A1,K2,A2,...) calcule K1*A1 + K2*A2 + ... en double,
  puis convertit une seule fois : les arrondis intermédiaires
  disparaissent, ce qui est le but de la fonction.

  Exemple :
     imlincomb(0.5, [1 2], 0.5, [3 4])   % [2 3]
```

## `immse`

```
IMMSE Erreur quadratique moyenne entre deux images.
  E = IMMSE(A,B) rend la moyenne des carrés des écarts, pixel à pixel.

  Elle vaut zéro pour deux images identiques et croît avec l'écart. Elle
  ne dit rien de la ressemblance perçue : deux images d'erreur
  quadratique égale peuvent être l'une très acceptable et l'autre
  inregardable, selon que l'erreur est répartie ou concentrée. C'est ce
  que les mesures perceptuelles — SSIM — cherchent à corriger.

  Le rapport signal à bruit de crête s'en déduit : PSNR = 10 log10(1/E)
  pour des images dans [0,1].

  Exemple :
     immse(ones(4), ones(4))         % 0
     immse(zeros(4), ones(4))        % 1

  Voir aussi PSNR, SSIM, IMABSDIFF.
```

## `immultiply`

```
IMMULTIPLY Produit terme à terme de deux images.
  Z = IMMULTIPLY(X,Y) multiplie terme à terme, ou par une constante.
  C'est ainsi qu'on applique un masque ou qu'on module une luminosité.

  Les opérations arithmétiques sur images saturent au lieu de déborder :
  sur des entiers, 200 + 100 vaut 255 et non 44. C'est ce qui les
  distingue de l'arithmétique ordinaire, et c'est presque toujours ce
  qu'on veut d'une image.

  Exemple :
     immultiply(uint8(200), 2)       % 255 : sature

  Voir aussi IMDIVIDE, IMADD, IMSUBTRACT.
```

## `imnoise`

```
IMNOISE Ajoute du bruit à une image.
  Y = IMNOISE(X,'gaussian',VAR) ajoute un bruit blanc gaussien.
  Y = IMNOISE(X,'salt & pepper',D) remplace une fraction D des pixels.

  Exemple :
     rng(1);
     x = 0.5 * ones(50);
     std(reshape(imnoise(x, 'gaussian', 0.01), [], 1)) > 0.05   % du bruit a ete ajoute
```

## `imopen`

```
IMOPEN Ouverture morphologique : érosion puis dilatation.
  Y = IMOPEN(X,ELEMENT) efface ce qui est plus petit que l'élément
  structurant, puis rend aux formes restantes leur taille.

  L'ouverture est idempotente : l'appliquer deux fois ne change rien de
  plus. C'est la propriété qui en fait un filtre au sens propre, et
  c'est ce qui la distingue d'une érosion suivie d'une dilatation
  quelconques.

  Elle ne peut que retirer : le résultat est contenu dans l'original.

  Exemple :
     bruite = false(20); bruite(5:15, 5:15) = true; bruite(2, 2) = true;
     propre = imopen(bruite, true(3));
     propre(2, 2)                    % false : le point isole a disparu

  Voir aussi IMCLOSE, IMERODE, IMDILATE.
```

## `imoverlay`

```
IMOVERLAY Pose un masque coloré sur une image.
  J = IMOVERLAY(I,BW) rend une image en couleurs où les points de BW
  sont peints en jaune, le reste gardant l'image d'origine. C'est la
  façon de montrer ce qu'une segmentation a trouvé.

  J = IMOVERLAY(I,BW,COULEUR) choisit la couleur : un triplet RVB entre
  0 et 1, ou un nom — 'red', 'green', 'blue', 'yellow', 'cyan',
  'magenta', 'white', 'black'.

  Exemple :
     I = mat2gray(peaks(60));
     J = imoverlay(I, I > 0.7, 'red');

  Voir aussi LABEL2RGB, IMSHOW, IMFUSE, BWPERIM.
```

## `impixel`

```
IMPIXEL Valeurs de pixels choisis.
  P = IMPIXEL(I,X,Y) rend, une ligne par point, les composantes des
  pixels aux colonnes X et aux lignes Y. Une image en niveaux de gris
  donne trois composantes égales, comme dans MATLAB.

  [R,V,B] = IMPIXEL(...) rend les trois composantes séparément.

  MATLAB permet aussi de cliquer les points dans la figure ; MatLibre
  n'a pas de figure cliquable, et demande donc les coordonnées.

  Exemple :
     I = mat2gray(magic(8));
     p = impixel(I, [1 8], [1 8]);

  Voir aussi IMSHOW, IMCROP, IMPROFILE, GINPUT.
```

## `impyramid`

```
IMPYRAMID Un étage de pyramide gaussienne, vers le haut ou vers le bas.
  IMPYRAMID(A,'reduce') divise la taille par deux après lissage ;
  'expand' la double.

  Le noyau est le noyau binomial 5 x 5 de Burt et Adelson, celui que
  MATLAB emploie : [1 4 6 4 1]/16 dans chaque direction.

  Exemple :
     size(impyramid(ones(32), 'reduce'))    % 16 16 : la taille est divisee par deux
     size(impyramid(ones(16), 'expand'))    % 31 31
```

## `imquantize`

```
IMQUANTIZE Quantifie une image selon des seuils.
  IDX = IMQUANTIZE(I,SEUILS) rend l'indice de classe, de 1 à
  numel(SEUILS)+1. [IDX,V] = IMQUANTIZE(...,NIVEAUX) rend aussi l'image
  reconstruite avec les valeurs données.

  Exemple :
     indices = imquantize([0.1 0.4 0.9], [0.3 0.6]);
     indices                     % 1 2 3 : trois classes pour deux seuils
```

## `imread`

```
IMREAD Lit une image aux formats PGM et PPM en texte (P2 et P3).
  X = IMREAD(FICHIER) rend une matrice de niveaux de gris pour un P2,
  un tableau à trois plans pour un P3.

  La classe rendue suit la valeur maximale déclarée dans le fichier :
  uint8 jusqu'à 255, uint16 au-delà. C'est la convention de MATLAB, et
  elle importe : une image entière et une image flottante ne se
  traitent pas de la même façon, et IM2DOUBLE existe pour passer de
  l'une à l'autre.

  Seuls les deux formats en texte sont lus. Les formats compressés —
  PNG, JPEG, TIFF — demandent une bibliothèque externe, que MatLibre
  n'emporte pas. Les commentaires, introduits par un dièse, sont
  ignorés.

  Exemple :
     imwrite(uint8(magic(8) * 4), 'essai.pgm');
     x = imread('essai.pgm');
     class(x)                        % uint8

  Voir aussi IMWRITE, IM2DOUBLE, IMSHOW.
```

## `imreconstruct`

```
IMRECONSTRUCT Reconstruction morphologique par dilatation géodésique.
  J = IMRECONSTRUCT(MARQUEUR,MASQUE) dilate le marqueur sous le masque
  jusqu'à stabilité : chaque pixel prend le maximum de son voisinage,
  sans jamais dépasser le masque. C'est la brique de toutes les
  opérations qui suivent — extrema régionaux, remplissage de trous,
  suppression des objets touchant le bord.

  L'implémentation fait deux balayages par tour, l'un en avant, l'autre
  en arrière : la propagation traverse alors l'image en un tour au lieu
  d'un par pixel de distance.

  Exemple :
     m = zeros(5); m(3,3) = 1;
     imreconstruct(m, ones(5))   % tout à 1 : le masque est connexe
```

## `imregionalmax`

```
IMREGIONALMAX Maxima régionaux d'une image.
  Un maximum régional est un plateau connexe dont tous les voisins sont
  strictement plus bas. On le trouve en reconstruisant l'image depuis
  elle-même diminuée d'un cran : ce qui reste au-dessus est un maximum.

  Le « cran » est pris sur les rangs des valeurs, pas sur les valeurs
  elles-mêmes : les maxima régionaux ne changent pas si l'on applique
  une fonction strictement croissante, et travailler sur les rangs rend
  le calcul exact même en présence d'infinis.

  Exemple :
     imregionalmax([1 2 1; 2 3 2; 1 2 1])   % le centre seulement
```

## `imregionalmin`

```
IMREGIONALMIN Minima régionaux d'une image.
  Dual d'IMREGIONALMAX, appliqué à l'image inversée.

  Exemple :
     x = [3 3 3; 3 1 3; 3 3 3];
     sum(sum(imregionalmin(x)))  % 1 : un seul minimum regional
```

## `imresize`

```
IMRESIZE Redimensionnement par interpolation bilinéaire.
  Y = IMRESIZE(X,F) multiplie les dimensions par F.
  Y = IMRESIZE(X,[H L]) impose la taille de sortie.

  Exemple :
     size(imresize(ones(10), 2))     % 20 20
     size(imresize(ones(10), 0.5))   % 5 5
```

## `imrotate`

```
IMROTATE Rotation d'une image, en degrés, autour de son centre.
  Y = IMROTATE(X,ANGLE) tourne X de ANGLE degrés dans le sens direct,
  par plus proche voisin, et agrandit l'image pour que rien n'en sorte.

  Y = IMROTATE(X,ANGLE,METHODE) où METHODE vaut 'nearest' (défaut),
  'bilinear' ou 'bicubic'.
  Y = IMROTATE(X,ANGLE,METHODE,CADRE) où CADRE vaut 'loose' (défaut,
  l'image grandit) ou 'crop' (même taille, les coins sortent).
  Y = IMROTATE(X,ANGLE,CADRE) accepte aussi le cadre seul.

  La rotation se calcule à l'envers : pour chaque pixel de la sortie on
  cherche d'où il vient dans l'entrée, et on y interpole. Faire
  l'inverse — envoyer chaque pixel d'entrée vers sa place de sortie —
  laisserait des trous, puisqu'une rotation ne fait pas correspondre
  les grilles.

  Les points qui viennent de l'extérieur de l'image sont mis à zéro.

  Exemple :
     I = mat2gray(peaks(100));
     J = imrotate(I, 30, 'bilinear');
     K = imrotate(I, 30, 'bilinear', 'crop');   % meme taille que I

  Voir aussi IMRESIZE, IMTRANSLATE, IMCROP, IMWARP.
```

## `imsharpen`

```
IMSHARPEN Accentue les contours par masque flou.
  R = IMSHARPEN(I,'Radius',R,'Amount',A) retranche une version floutée :
  R = I + A*(I - flou(I)). Le rayon vaut 1 et le montant 0,8 par défaut,
  comme dans MATLAB.

  Exemple :
     rng(1);
     x = imboxfilt(rand(30), 5);
     std(reshape(imsharpen(x), [], 1)) > std(x(:))   % l'accentuation releve le contraste
```

## `imshow`

```
IMSHOW Affiche une image dans les axes courants.
  Le rendu se fait en SVG : « print » écrit le fichier.

  Exemple :
     imshow(rand(16));
     close all;
```

## `imsplit`

```
IMSPLIT Sépare les plans d'une image en autant de sorties.
  [R,V,B] = IMSPLIT(RGB).

  Exemple :
     [r, v, b] = imsplit(zeros(4, 4, 3));
```

## `imsubtract`

```
IMSUBTRACT Différence de deux images, avec saturation pour les entiers.
  Z = IMSUBTRACT(X,Y) soustrait terme à terme.

  Les opérations arithmétiques sur images saturent au lieu de déborder :
  sur des entiers, 200 + 100 vaut 255 et non 44. C'est ce qui les
  distingue de l'arithmétique ordinaire, et c'est presque toujours ce
  qu'on veut d'une image.

  Exemple :
     imsubtract(uint8(50), uint8(100))   % 0, non 206

  Voir aussi IMADD, IMABSDIFF, IMMULTIPLY.
```

## `imtophat`

```
IMTOPHAT Chapeau haut de forme : l'image moins son ouverture.
  Fait ressortir les détails clairs plus petits que l'élément
  structurant.

  Exemple :
     bw = zeros(20);
     bw(10, 10) = 1;             % un point isole
     sum(sum(imtophat(bw, ones(3)))) > 0   % le chapeau haut de forme le voit
```

## `imtranslate`

```
IMTRANSLATE Décale une image d'un nombre entier de pixels.
  R = IMTRANSLATE(I,[DX DY]) décale de DX colonnes et DY lignes ; les
  pixels qui entrent valent zéro. Les décalages non entiers sont
  arrondis.

  Exemple :
     r = imtranslate([1 2 3; 4 5 6; 7 8 9], [1 0]);
     r(1, :)                     % 0 1 2 : tout a glisse d'une colonne
```

## `imwrite`

```
IMWRITE Écrit une image au format PGM (gris) ou PPM (couleur).
  Ces deux formats sont du texte : aucune bibliothèque externe n'est
  nécessaire, et tous les visionneurs les lisent.

  Exemple :
     imwrite(uint8(magic(8) * 4), 'essai.pgm');
     max(max(abs(double(imread('essai.pgm')) - magic(8) * 4)))   % 0 : rien ne se perd
```

## `ind2gray`

```
IND2GRAY Image indexée vers niveaux de gris.
  La luminance suit la même pondération que RGB2GRAY.

  Exemple :
     g = ind2gray([1 2 3], [0 0 0; 0.5 0.5 0.5; 1 1 1]);
     g                           % 0 0.5 1
```

## `ind2rgb`

```
IND2RGB Image indexée vers image en couleurs.
  RGB = IND2RGB(X,CARTE) remplace chaque indice par la couleur qu'il
  désigne dans la palette.

  Une image indexée sépare la géométrie de la couleur : la même image
  change entièrement d'aspect quand on change de palette, sans qu'aucun
  pixel ne bouge. C'est ce qui rend les fausses couleurs si commodes
  pour lire une carte de valeurs.

  Exemple :
     rgb = ind2rgb(round(rand(8) * 63) + 1, jet(64));
     size(rgb)                       % 8 8 3

  Voir aussi GRAY2RGB, RGB2GRAY, COLORMAP.
```

## `lab2rgb`

```
LAB2RGB Passage de L*a*b* à sRGB.
  RGB = LAB2RGB(LAB) convertit depuis l'espace perceptuel CIE L*a*b*,
  où L est la clarté de 0 à 100, a et b les deux axes chromatiques.

  L'intérêt de L*a*b* est que la distance euclidienne y correspond à peu
  près à l'écart perçu : deux couleurs à même distance y paraissent
  également différentes, ce qui n'est pas du tout le cas en RVB. C'est
  pourquoi on y calcule les différences de couleur et les segmentations.

  Il est aussi bien plus vaste que le sRGB : une conversion peut sortir
  de l'intervalle [0,1], et il faut alors écrêter.

  Exemple :
     lab2rgb([100 0 0])              % blanc
     lab2rgb([0 0 0])                % noir

  Voir aussi RGB2LAB, YCBCR2RGB, NTSC2RGB.
```

## `lab2xyz`

```
LAB2XYZ Passage de L*a*b* à XYZ.
  Réciproque exacte de XYZ2LAB.

  Exemple :
     xyz = lab2xyz([100 0 0]);
     max(abs(xyz - [0.9504 1 1.0888])) < 1e-3   % L = 100 : le blanc D65
```

## `label2rgb`

```
LABEL2RGB Colorie une image étiquetée.
  RGB = LABEL2RGB(L) donne une couleur par étiquette ; le fond (zéro)
  reste blanc. LABEL2RGB(L,CARTE,FOND) choisit la palette et la couleur
  du fond.

  Exemple :
     couleurs = label2rgb([0 1; 2 0]);
     size(couleurs)              % 2 2 3 : une image couleur
```

## `lin2rgb`

```
LIN2RGB Applique la correction gamma de sRGB.
  Réciproque exacte de RGB2LIN.

  Exemple :
     lin2rgb(0.214)   % 0.4999
```

## `mat2gray`

```
MAT2GRAY Ramène une matrice dans l'intervalle [0,1].
  I = MAT2GRAY(A) rend une image d'intensité : le minimum de A devient
  0, le maximum 1, et le reste s'échelonne linéairement entre les deux.
  C'est ce qu'il faut pour montrer une matrice quelconque comme une
  image.

  I = MAT2GRAY(A,[BAS HAUT]) fixe les deux bornes : ce qui est en
  dessous de BAS devient 0, ce qui est au-dessus de HAUT devient 1.

  Exemple :
     I = mat2gray(magic(4));
     [min(I(:)) max(I(:))]     % [0 1]

  Voir aussi IMADJUST, IM2DOUBLE, IMSHOW, RESCALE, STRETCHLIM.
```

## `matriceRVBversXYZ`

```
MATRICERVBVERSXYZ Matrice sRGB linéaire vers XYZ, blanc D65.
  Les coefficients sont ceux de la recommandation UIT-R BT.709, celle
  que sRGB reprend : ils envoient le blanc [1 1 1] sur le blanc D65.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.

  Exemple :
     M = matriceRVBversXYZ();
     max(abs(M * [1; 1; 1] - [0.95047; 1; 1.08883])) < 1e-3   % le blanc va sur D65
```

## `mean2`

```
MEAN2 Moyenne de tous les éléments d'une matrice.
  M = MEAN2(A) est un raccourci pour MEAN(A(:)) : la moyenne de toute la
  matrice, non celle de chaque colonne.

  C'est la confusion la plus fréquente sur une image : MEAN(image) rend
  une ligne de moyennes par colonne, ce qui n'est presque jamais ce
  qu'on veut.

  Exemple :
     mean2(magic(4))                 % 8.5
     mean(magic(4))                  % [8.5 8.5 8.5 8.5] : par colonne

  Voir aussi STD2, MEAN, IMHIST.
```

## `medfilt2`

```
MEDFILT2 Filtre médian bidimensionnel.
  Y = MEDFILT2(X,[M N]) remplace chaque pixel par la médiane de son
  voisinage, de taille 3 sur 3 par défaut.

  La médiane n'est pas une moyenne : elle efface complètement un point
  isolé aberrant, là où la moyenne l'étale sur tout le voisinage. C'est
  pourquoi elle est le remède au bruit poivre et sel, et pourquoi elle
  conserve les contours francs qu'un lissage gaussien émousserait.

  Elle n'est pas linéaire : la médiane d'une somme n'est pas la somme
  des médianes, et aucune analyse en fréquence ne la décrit.

  Exemple :
     image = ones(9); image(5, 5) = 100;
     medfilt2(image)(5, 5)           % 1 : l'aberrant a disparu

  Voir aussi IMGAUSSFILT, IMFILTER, MEDIAN.
```

## `montage`

```
MONTAGE Affiche plusieurs images en mosaïque.
  MONTAGE(I) affiche côte à côte les images d'un tableau à quatre
  dimensions — hauteur, largeur, canaux, nombre — ou d'un tableau de
  cellules d'images.

  MONTAGE(...,'Size',[L C]) impose le découpage ; sans lui, la
  mosaïque est aussi carrée que possible.
  MONTAGE(...,'BorderSize',B) sépare les vignettes de B pixels,
  'BackgroundColor',C donne la couleur du fond, 'DisplayRange',[A B]
  l'étendue des valeurs.

  H = MONTAGE(...) rend l'image assemblée.

  Exemple :
     images = cat(4, mat2gray(peaks(40)), mat2gray(magic(40)));
     montage(images);

  Voir aussi IMSHOW, IMTILE, SUBPLOT, IMSHOWPAIR.
```

## `morphologie`

```
MORPHOLOGIE Noyau commun de l'érosion et de la dilatation.
  Hors de l'image, le voisinage vaut l'élément neutre de l'opération :
  plus l'infini pour l'érosion, moins l'infini pour la dilatation. Un
  pixel dont tout le voisinage sort du cadre garde donc sa valeur
  neutre, au lieu de faire échouer le calcul sur un ensemble vide.

  Exemple :
     bw = false(10);
     bw(5, 5) = true;
     sum(sum(morphologie(double(bw), ones(3), 'dilate')))   % 9 : le point s'epaissit
```

## `multithresh`

```
MULTITHRESH Seuils d'Otsu multiples.
  S = MULTITHRESH(I,N) rend N seuils qui découpent l'histogramme en N+1
  classes en maximisant la variance interclasse — la généralisation
  directe de la méthode d'Otsu.

  Exemple :
     multithresh([zeros(1,50) ones(1,50)], 1)   % proche de 0,5
```

## `nlfilter`

```
NLFILTER Filtre défini par une fonction du voisinage.
  B = NLFILTER(A,[M N],FUN) applique FUN à chaque voisinage glissant de
  M x N pixels ; le résultat prend la valeur rendue par FUN.

  Exemple :
     nlfilter(magic(4), [3 3], @(x) max(x(:)))
```

## `normxcorr2`

```
NORMXCORR2 Corrélation croisée normalisée.
  C = NORMXCORR2(MOTIF,IMAGE) rend la corrélation du motif avec
  l'image, normalisée en chaque position par les écarts types locaux :
  le résultat est entre -1 et 1, et vaut 1 là où le motif se retrouve
  exactement, à un facteur d'échelle et un décalage près.

  C'est ce qui distingue la corrélation normalisée de la corrélation
  ordinaire : celle-ci répond fort partout où l'image est claire, sans
  égard à la forme.

  C a la taille de l'image augmentée du motif moins un ; le maximum se
  trouve au coin bas-droit de la position du motif.

  Exemple :
     I = mat2gray(peaks(60));
     motif = I(20:30, 25:35);
     C = normxcorr2(motif, I);
     [~, k] = max(C(:));
     [ligne, colonne] = ind2sub(size(C), k);   % 30 et 35

  Voir aussi XCORR2, CORR2, IMFILTER, CONV2, IMREGCORR.
```

## `ntsc2rgb`

```
NTSC2RGB Passage de YIQ à RVB.
  RGB = NTSC2RGB(YIQ) convertit depuis l'espace de la télévision
  analogique : Y la luminance, I et Q les deux axes de chrominance.

  Le choix des axes I et Q n'est pas arbitraire : ils sont orientés
  selon les directions où l'œil discrimine le mieux et le moins bien,
  ce qui permettait de leur donner des bandes passantes différentes.
  C'est la même idée que le sous-échantillonnage de la chrominance en
  numérique, née trente ans plus tôt.

  Le canal Y seul donne une image en niveaux de gris compatible avec un
  téléviseur noir et blanc : c'est ce qui a permis la transition.

  Exemple :
     ntsc2rgb([1 0 0])               % blanc : chrominance nulle

  Voir aussi RGB2NTSC, YCBCR2RGB, RGB2GRAY.
```

## `ordfilt2`

```
ORDFILT2 Filtre de rang : le ORDRE-ième plus petit du voisinage.
  R = ORDFILT2(I,N,DOMAINE) où DOMAINE est une matrice logique qui dit
  quels voisins comptent. Avec N = 1 c'est un minimum, avec N égal au
  nombre de vrais c'est un maximum, et au milieu c'est la médiane.
  Les bords sont complétés par des zéros, comme dans MATLAB ;
  ORDFILT2(...,'symmetric') les complète par symétrie.

  Exemple :
     ordfilt2(magic(4), 9, ones(3))   % maximum sur 3x3
```

## `padarray`

```
PADARRAY Ajoute une bordure à un tableau.
  B = PADARRAY(A,[M N]) ajoute M lignes et N colonnes de zéros de chaque
  côté. PADARRAY(A,T,VALEUR) remplit avec VALEUR ; VALEUR peut aussi
  valoir 'replicate' (répète le bord), 'symmetric' (miroir) ou
  'circular' (périodique). PADARRAY(A,T,VALEUR,DIRECTION) où DIRECTION
  vaut 'both' (défaut), 'pre' ou 'post'.

  Exemple :
     padarray([1 2; 3 4], [1 1])   % entouré de zéros
```

## `poly2mask`

```
POLY2MASK Masque des points intérieurs à un polygone.
  BW = POLY2MASK(X,Y,M,N) rend une image binaire de M lignes et N
  colonnes, vraie aux pixels dont le centre est à l'intérieur du
  polygone de sommets (X,Y). Le polygone est refermé sur lui-même.

  Le test d'appartenance est celui du nombre de traversées : une
  demi-droite partant du point coupe un nombre impair de côtés si et
  seulement si le point est dedans.

  Exemple :
     BW = poly2mask([2 8 8 2], [2 2 8 8], 10, 10);
     sum(BW(:))

  Voir aussi ROIPOLY, INPOLYGON, ROIFILT2, ROICOLOR, REGIONPROPS.
```

## `psnr`

```
PSNR Rapport signal sur bruit de crête, en décibels.
  P = PSNR(A,REF) ; MAXIMUM vaut 1 pour un double et 255 pour un uint8.

  Exemple :
     rng(1);
     x = rand(32, 32);
     psnr(x, x)                  % Inf : deux images identiques
     psnr(x, x + 0.01 * randn(32, 32)) > 30
```

## `rangefilt`

```
RANGEFILT Étendue locale : maximum moins minimum du voisinage.
  Les bords sont complétés par symétrie, comme dans MATLAB : une image
  constante a donc une étendue nulle partout, bords compris.

  Exemple :
     rangefilt([1 2; 3 4])(1, 1)   % 3
```

## `regionprops`

```
REGIONPROPS Mesures sur les régions d'une image étiquetée.
  S = REGIONPROPS(BW) ou REGIONPROPS(L) rend un tableau de structures,
  une par région. Mesures reconnues : 'Area', 'Centroid',
  'BoundingBox', 'PixelIdxList', 'PixelList', 'MajorAxisLength',
  'MinorAxisLength', 'Orientation', 'Perimeter', 'Eccentricity',
  'EquivDiameter', 'Extent', 'FilledArea', 'all'.

  Exemple :
     s = regionprops(bwlabel([1 1 0; 1 1 0; 0 0 1]));
     s(1).Area   % 4
```

## `rgb2gray`

```
RGB2GRAY Luminance d'une image couleur.
  G = RGB2GRAY(RGB) applique la pondération de la recommandation
  ITU-R BT.601 : environ 0,299 R + 0,587 V + 0,114 B.

  Les trois poids ne sont pas égaux parce que l'œil ne l'est pas : il
  est bien plus sensible au vert qu'au bleu. Une moyenne arithmétique
  des trois canaux donnerait une image grise, mais pas la bonne — les
  verts y paraîtraient trop sombres et les bleus trop clairs.

  Les coefficients sont donnés à leur pleine précision, celle de
  l'inversion de la matrice de la recommandation : ils somment
  exactement à un, si bien qu'un gris reste ce qu'il est. Les valeurs
  arrondies à quatre décimales, elles, somment à 0,9999 et assombrissent
  imperceptiblement toute l'image.

  Une image déjà en niveaux de gris est rendue telle quelle.

  Exemple :
     gris = repmat(0.5, 2, 2, 3);
     max(max(abs(rgb2gray(gris) - 0.5)))  % 0 : le gris est conserve

  Voir aussi IM2DOUBLE, IMADJUST, IMHIST.
```

## `rgb2hsv`

```
RGB2HSV Couleurs RVB vers teinte, saturation, valeur.
  H = RGB2HSV(IMAGE) où IMAGE est MxNx3 dans [0,1], ou RGB2HSV(CARTE)
  où CARTE est une carte de couleurs Mx3. Les trois plans du résultat
  sont la teinte (0 à 1), la saturation et la valeur.

  Exemple :
     c = rgb2hsv(cat(3, 1, 0, 0));   % rouge pur : teinte 0, S = V = 1
```

## `rgb2ind`

```
RGB2IND Image en couleurs vers image indexée.
  [X,MAP] = RGB2IND(RGB,N) réduit l'image à N couleurs par les
  k-moyennes sur les pixels, initialisées régulièrement pour que le
  résultat ne dépende pas du tirage.

  [X,MAP] = RGB2IND(RGB,MAP) utilise la palette donnée et affecte
  chaque pixel à sa couleur la plus proche.

  Exemple :
     [x, map] = rgb2ind(cat(3, [0 1], [0 1], [0 1]), 2);
```

## `rgb2lab`

```
RGB2LAB Passage de sRGB à L*a*b*.
  L* va de 0 à 100, a* et b* sont centrés sur zéro. C'est l'espace où
  les distances euclidiennes correspondent le mieux aux différences
  perçues.

  Exemple :
     rgb2lab([1 1 1])   % [100 0 0]
```

## `rgb2lin`

```
RGB2LIN Défait la correction gamma d'une image sRGB.
  U = RGB2LIN(V) applique la fonction de transfert inverse de sRGB :
  une droite près de zéro, une puissance 2,4 au-delà. Les valeurs
  entrent et sortent entre 0 et 1.

  Exemple :
     rgb2lin(0.5)   % 0.2140
```

## `rgb2ntsc`

```
RGB2NTSC Passage de RVB à l'espace YIQ de la télévision NTSC.
  Y porte la luminance, I et Q la chrominance. La première ligne de la
  matrice est celle de RGB2GRAY.

  Exemple :
     rgb2ntsc([1 1 1])   % [1 0 0]
```

## `rgb2xyz`

```
RGB2XYZ Passage de sRGB à l'espace XYZ de la CIE.
  XYZ = RGB2XYZ(RGB) linéarise d'abord l'image, puis applique la
  matrice de la recommandation BT.709.

  RGB2XYZ(...,'WhitePoint',W) adapte le résultat à un autre blanc que
  le D65 de sRGB, par la mise à l'échelle de von Kries.

  Exemple :
     rgb2xyz([1 1 1])   % le blanc D65
```

## `rgb2ycbcr`

```
RGB2YCBCR Couleurs RVB vers luminance et chrominances.
  Y = RGB2YCBCR(IMAGE) applique la matrice de la recommandation
  ITU-R BT.601, avec les plages 16..235 et 16..240 de MATLAB pour les
  entiers 8 bits, et les mêmes valeurs ramenées à [0,1] pour un double.

  Exemple :
     max(abs(ycbcr2rgb(rgb2ycbcr([0.2 0.4 0.6])) - [0.2 0.4 0.6])) < 1e-5   % l'aller-retour
```

## `roicolor`

```
ROICOLOR Sélectionne une région par son intensité.
  BW = ROICOLOR(A,BAS,HAUT) rend le masque des points dont la valeur
  est comprise entre BAS et HAUT.
  BW = ROICOLOR(A,V) rend le masque des points dont la valeur figure
  dans le vecteur V.

  Exemple :
     BW = roicolor(magic(5), 10, 20);

  Voir aussi ROIFILT2, POLY2MASK, IMBINARIZE, IMQUANTIZE.
```

## `roifilt2`

```
ROIFILT2 Filtre une image à l'intérieur d'une région seulement.
  J = ROIFILT2(H,I,BW) filtre I par le noyau H, mais ne garde le
  résultat que là où BW est vrai : ailleurs, l'image d'origine est
  conservée.

  J = ROIFILT2(I,BW,F) applique la fonction F à l'image entière et n'en
  garde que la région.

  Exemple :
     I = mat2gray(peaks(50));
     BW = poly2mask([10 40 40 10], [10 10 40 40], 50, 50);
     J = roifilt2(fspecial('average', 5), I, BW);

  Voir aussi IMFILTER, POLY2MASK, ROICOLOR, NLFILTER, BLOCKPROC.
```

## `ssim`

```
SSIM Indice de similarité structurelle.
  S = SSIM(A,REF) rend l'indice global, entre -1 et 1 ; 1 signifie que
  les deux images sont identiques. La fenêtre est une gaussienne de
  11 points et d'écart-type 1,5, comme dans l'article de Wang et al.
  et dans MATLAB.

  Exemple :
     rng(1);
     x = rand(32, 32);
     ssim(x, x)                  % 1 : la ressemblance parfaite
     ssim(x, x + 0.1 * randn(32, 32)) < 1
```

## `std2`

```
STD2 Écart-type de tous les éléments d'une matrice.
  S = STD2(A) est un raccourci pour STD(A(:)).

  Sur une image, il mesure le contraste global : une image uniforme a un
  écart type nul, une image très contrastée un écart type proche de la
  moitié de sa dynamique.

  Exemple :
     std2(ones(8))                   % 0 : aucune variation
     std2(magic(4)) > 0              % true

  Voir aussi MEAN2, STD, HISTEQ.
```

## `stdfilt`

```
STDFILT Écart-type local.
  R = STDFILT(I,VOISINAGE) rend l'écart-type des pixels du voisinage,
  normalisé par n-1 comme le fait MATLAB.

  Exemple :
     r = stdfilt(ones(10));
     max(r(:)) < 1e-12           % un plateau n'a pas d'ecart type
```

## `strel`

```
STREL Élément structurant pour la morphologie.
  S = STREL('square',N), STREL('rectangle',[M N]), STREL('disk',R),
  STREL('line',LONGUEUR,ANGLE), STREL('diamond',R), STREL('arbitrary',M).
  Le résultat est une matrice logique, directement utilisable par
  IMDILATE, IMERODE, IMOPEN et IMCLOSE.

  Exemple :
     strel('square', 3)   % 3x3 de vrais
```

## `stretchlim`

```
STRETCHLIM Bornes de contraste, pour IMADJUST.
  L = STRETCHLIM(I,TOL) rend [bas; haut] tels que la proportion TOL(1)
  des pixels soit sous « bas » et TOL(2) au-dessus de « haut ». TOL vaut
  [0.01 0.99] par défaut.

  Exemple :
     limites = stretchlim([0.2 0.5 0.8]);
     limites(1) < limites(2)     % 1 : la borne basse precede la haute
```

## `voisinageConnexite`

```
VOISINAGECONNEXITE Décalages [di dj] d'une connexité 2-D.
  Accepte 4, 8 ou un tableau logique 3 x 3.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.

  Exemple :
     size(voisinageConnexite(4), 1)     % 4 decalages
     size(voisinageConnexite(8), 1)     % 8
```

## `watershed`

```
WATERSHED Ligne de partage des eaux.
  L = WATERSHED(A) inonde le relief A depuis ses minima régionaux : les
  pixels reçoivent le numéro du bassin qui les a atteints, et ceux où
  deux bassins se rejoignent restent à zéro — c'est la ligne de
  partage.

  L'inondation suit l'algorithme de Meyer : on traite les pixels par
  altitude croissante, en propageant l'étiquette du voisin déjà
  inondé, et l'on marque la crête quand deux étiquettes se disputent
  le même pixel.

  Exemple :
     relief = [1 2 3 2 1];
     watershed(relief)   % deux bassins séparés par le sommet
```

## `whitepoint`

```
WHITEPOINT Coordonnées XYZ d'un blanc de référence.
  XYZ = WHITEPOINT(NOM) où NOM vaut 'ICC' (par défaut), 'D50', 'D55',
  'D65', 'A' ou 'C'. Le blanc est normalisé à Y = 1.

  Exemple :
     whitepoint('d65')   % [0.9504 1.0000 1.0888]
```

## `xyz2lab`

```
XYZ2LAB Passage de XYZ à L*a*b*.
  Le blanc de référence est le D65 par défaut ; l'option 'WhitePoint'
  en choisit un autre.

  Exemple :
     xyz2lab(whitepoint('d65'))   % [100 0 0], le blanc parfait
```

## `xyz2rgb`

```
XYZ2RGB Passage de l'espace XYZ à sRGB.
  Réciproque de RGB2XYZ. Les valeurs hors du domaine affichable sont
  ramenées entre 0 et 1, comme le fait MATLAB.

  Exemple :
     rgb = xyz2rgb([0.9504 1 1.0888]);
     max(abs(rgb - [1 1 1])) < 1e-2      % le blanc D65 donne du blanc
```

## `ycbcr2rgb`

```
YCBCR2RGB Luminance et chrominances vers RVB.
  RGB = YCBCR2RGB(YCBCR) convertit depuis l'espace de la télévision et
  de la compression : Y la luminance, Cb et Cr les deux différences de
  couleur.

  La séparation n'est pas décorative : l'œil est bien plus sensible à la
  luminance qu'à la chrominance, si bien que JPEG et la vidéo
  sous-échantillonnent Cb et Cr sans que cela se voie. C'est là que la
  moitié du gain de compression se fait.

  Une entrée entière est traitée dans les plages de la vidéo — 16 à 235
  pour Y, 16 à 240 pour Cb et Cr — et une entrée flottante dans [0,1].

  L'entrée peut être une image H x L x 3 ou une liste N x 3 de couleurs,
  une par ligne ; la sortie garde la forme de l'entrée.

  Exemple :
     ycbcr2rgb([1 0.5 0.5])          % blanc : chrominance neutre

  Voir aussi RGB2YCBCR, NTSC2RGB, LAB2RGB.
```

