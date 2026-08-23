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
%   edge        - Détection de contours
%
% Histogramme et contraste
%   imhist, histeq, imadjust, stretchlim
%   graythresh, imbinarize, multithresh, imquantize
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
```

## `bwarea`

```
BWAREA Aire d'une région binaire, en pixels.
```

## `bwconncomp`

```
BWCONNCOMP Composantes connexes d'une image binaire.
  CC = BWCONNCOMP(BW,CONNEXITE) rend une structure aux champs
  Connectivity, ImageSize, NumObjects et PixelIdxList — la même que
  celle de MATLAB.
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
```

## `bwlabel`

```
BWLABEL Étiquetage des composantes connexes d'une image binaire.
  [L,N] = BWLABEL(BW) numérote les régions de pixels vrais.
  CONNEXITE vaut 4 ou 8 (8 par défaut).
```

## `bwperim`

```
BWPERIM Contour d'une région binaire.
  P = BWPERIM(BW) garde les pixels vrais qui touchent au moins un pixel
  faux dans le voisinage à quatre voisins.

  Exemple :
     sum(sum(bwperim(true(3))))   % 8 : tout sauf le centre
```

## `corr2`

```
CORR2 Coefficient de corrélation entre deux matrices de même taille.
  Exemple :  corr2(magic(4), magic(4))   % 1
```

## `dct2`

```
DCT2 Transformée en cosinus discrète bidimensionnelle.
  Y = DCT2(X) applique DCT aux colonnes puis aux lignes.
```

## `edge`

```
EDGE Détection de contours.
  C = EDGE(X) applique Sobel avec un seuil automatique.
  C = EDGE(X,'sobel'|'prewitt'|'log',SEUIL) choisit la méthode.
```

## `entropyfilt`

```
ENTROPYFILT Entropie locale, en bits.
  L'histogramme est calculé sur 256 niveaux, comme dans MATLAB.
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
```

## `gray2rgb`

```
GRAY2RGB Réplique une image en niveaux de gris sur trois canaux.
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
```

## `graythresh`

```
GRAYTHRESH Seuil global par la méthode d'Otsu.
  SEUIL = GRAYTHRESH(X) maximise la variance interclasse.
```

## `histeq`

```
HISTEQ Égalisation d'histogramme.
```

## `hsv2rgb`

```
HSV2RGB Teinte, saturation, valeur vers RVB.
  R = HSV2RGB(IMAGE) où IMAGE est MxNx3.
```

## `idct2`

```
IDCT2 Transformée en cosinus discrète inverse bidimensionnelle.
```

## `im2double`

```
IM2DOUBLE Convertit une image en double dans [0,1].
```

## `im2gray`

```
IM2GRAY Rend une image en niveaux de gris, quelle que soit l'entrée.
  Une image déjà en niveaux de gris ressort inchangée.
```

## `im2uint8`

```
IM2UINT8 Convertit une image en uint8 (0 à 255).
```

## `imabsdiff`

```
IMABSDIFF Différence absolue de deux images, sans dépassement.
```

## `imadd`

```
IMADD Somme de deux images, avec saturation pour les entiers.
```

## `imadjust`

```
IMADJUST Étirement de contraste.
  Y = IMADJUST(X,[BAS HAUT],[NBAS NHAUT],GAMMA) applique la transformation
  affine par morceaux suivie de la correction gamma.
```

## `imbinarize`

```
IMBINARIZE Seuillage d'une image en niveaux de gris.
```

## `imbothat`

```
IMBOTHAT Chapeau bas de forme : la fermeture moins l'image.
  Fait ressortir les détails sombres.
```

## `imboxfilt`

```
IMBOXFILT Filtre moyenneur, à noyau carré.
  R = IMBOXFILT(I,N) moyenne sur un carré de N points de côté ; N est
  impair. C'est le filtre le moins cher, et le plus flou.
```

## `imclose`

```
IMCLOSE Fermeture morphologique : dilatation puis érosion.
```

## `imcomplement`

```
IMCOMPLEMENT Négatif d'une image.
  Pour un double dans [0,1], c'est 1-X ; pour un uint8, 255-X ; pour un
  logique, la négation.
```

## `imcrop`

```
IMCROP Découpe un rectangle [x y largeur hauteur] dans une image.
```

## `imdilate`

```
IMDILATE Dilatation morphologique.
```

## `imdivide`

```
IMDIVIDE Quotient terme à terme de deux images.
```

## `imerode`

```
IMERODE Érosion morphologique.
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

## `imgaussfilt`

```
IMGAUSSFILT Lissage gaussien d'une image.
```

## `imgradient`

```
IMGRADIENT Amplitude et direction du gradient.
  [G,DIR] = IMGRADIENT(I) ou IMGRADIENT(GX,GY). La direction est en
  degrés, comptée depuis l'axe des x, positive dans le sens
  trigonométrique.
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
```

## `immultiply`

```
IMMULTIPLY Produit terme à terme de deux images.
```

## `imnoise`

```
IMNOISE Ajoute du bruit à une image.
  Y = IMNOISE(X,'gaussian',VAR) ajoute un bruit blanc gaussien.
  Y = IMNOISE(X,'salt & pepper',D) remplace une fraction D des pixels.
```

## `imopen`

```
IMOPEN Ouverture morphologique : érosion puis dilatation.
```

## `imquantize`

```
IMQUANTIZE Quantifie une image selon des seuils.
  IDX = IMQUANTIZE(I,SEUILS) rend l'indice de classe, de 1 à
  numel(SEUILS)+1. [IDX,V] = IMQUANTIZE(...,NIVEAUX) rend aussi l'image
  reconstruite avec les valeurs données.
```

## `imread`

```
IMREAD Lit une image aux formats PGM/PPM en texte (P2 et P3).
```

## `imresize`

```
IMRESIZE Redimensionnement par interpolation bilinéaire.
  Y = IMRESIZE(X,F) multiplie les dimensions par F.
  Y = IMRESIZE(X,[H L]) impose la taille de sortie.
```

## `imrotate`

```
IMROTATE Rotation d'une image, en degrés, autour de son centre.
```

## `imsharpen`

```
IMSHARPEN Accentue les contours par masque flou.
  R = IMSHARPEN(I,'Radius',R,'Amount',A) retranche une version floutée :
  R = I + A*(I - flou(I)). Le rayon vaut 1 et le montant 0,8 par défaut,
  comme dans MATLAB.
```

## `imshow`

```
IMSHOW Affiche une image dans les axes courants.
  Le rendu se fait en SVG : « print » écrit le fichier.
```

## `imsubtract`

```
IMSUBTRACT Différence de deux images, avec saturation pour les entiers.
```

## `imtophat`

```
IMTOPHAT Chapeau haut de forme : l'image moins son ouverture.
  Fait ressortir les détails clairs plus petits que l'élément
  structurant.
```

## `imtranslate`

```
IMTRANSLATE Décale une image d'un nombre entier de pixels.
  R = IMTRANSLATE(I,[DX DY]) décale de DX colonnes et DY lignes ; les
  pixels qui entrent valent zéro. Les décalages non entiers sont
  arrondis.
```

## `imwrite`

```
IMWRITE Écrit une image au format PGM (gris) ou PPM (couleur).
  Ces deux formats sont du texte : aucune bibliothèque externe n'est
  nécessaire, et tous les visionneurs les lisent.
```

## `label2rgb`

```
LABEL2RGB Colorie une image étiquetée.
  RGB = LABEL2RGB(L) donne une couleur par étiquette ; le fond (zéro)
  reste blanc. LABEL2RGB(L,CARTE,FOND) choisit la palette et la couleur
  du fond.
```

## `mean2`

```
MEAN2 Moyenne de tous les éléments d'une matrice.
```

## `medfilt2`

```
MEDFILT2 Filtre médian bidimensionnel.
```

## `morphologie`

```
MORPHOLOGIE Noyau commun de l'érosion et de la dilatation.
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

## `psnr`

```
PSNR Rapport signal sur bruit de crête, en décibels.
  P = PSNR(A,REF) ; MAXIMUM vaut 1 pour un double et 255 pour un uint8.

  Exemple :  psnr(x, x)   % Inf
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
  ITU-R BT.601 : 0.2989 R + 0.5870 V + 0.1140 B.
```

## `rgb2hsv`

```
RGB2HSV Couleurs RVB vers teinte, saturation, valeur.
  H = RGB2HSV(IMAGE) où IMAGE est MxNx3 dans [0,1]. Les trois plans du
  résultat sont la teinte (0 à 1), la saturation et la valeur.

  Exemple :
     c = rgb2hsv(cat(3, 1, 0, 0));   % rouge pur : teinte 0, S = V = 1
```

## `rgb2ycbcr`

```
RGB2YCBCR Couleurs RVB vers luminance et chrominances.
  Y = RGB2YCBCR(IMAGE) applique la matrice de la recommandation
  ITU-R BT.601, avec les plages 16..235 et 16..240 de MATLAB pour les
  entiers 8 bits, et les mêmes valeurs ramenées à [0,1] pour un double.
```

## `ssim`

```
SSIM Indice de similarité structurelle.
  S = SSIM(A,REF) rend l'indice global, entre -1 et 1 ; 1 signifie que
  les deux images sont identiques. La fenêtre est une gaussienne de
  11 points et d'écart-type 1,5, comme dans l'article de Wang et al.
  et dans MATLAB.

  Exemple :  ssim(x, x)   % 1
```

## `std2`

```
STD2 Écart-type de tous les éléments d'une matrice.
```

## `stdfilt`

```
STDFILT Écart-type local.
  R = STDFILT(I,VOISINAGE) rend l'écart-type des pixels du voisinage,
  normalisé par n-1 comme le fait MATLAB.
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
```

## `ycbcr2rgb`

```
YCBCR2RGB Luminance et chrominances vers RVB.
```

