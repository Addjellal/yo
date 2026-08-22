# Toolbox `images`

```
% Image Processing Toolbox — traitement d'images.
%
% Une image est une matrice : niveaux de gris en 2-D, couleur en 3-D
% (hauteur x largeur x 3). Les entiers uint8 valent 0 à 255, les doubles
% 0 à 1, comme dans la documentation MathWorks.
%
%   im2double, im2uint8   - Conversions d'échelle
%   rgb2gray, gray2rgb    - Couleur et niveaux de gris
%   imresize              - Redimensionnement bilinéaire
%   imrotate              - Rotation
%   imcrop                - Découpe
%   imfilter, fspecial    - Filtrage linéaire et noyaux usuels
%   imgaussfilt           - Lissage gaussien
%   medfilt2              - Filtre médian 2-D
%   edge                  - Détection de contours (Sobel, Prewitt, Laplacien)
%   imbinarize, graythresh- Seuillage, méthode d'Otsu
%   imadjust, histeq      - Contraste et égalisation d'histogramme
%   imhist                - Histogramme
%   imerode, imdilate     - Morphologie mathématique
%   imopen, imclose       - Ouverture et fermeture
%   bwlabel               - Étiquetage des composantes connexes
%   imnoise               - Ajout de bruit
%   imshow, imwrite       - Affichage et écriture (PGM/PPM)
```

## `bwlabel`

```
BWLABEL Étiquetage des composantes connexes d'une image binaire.
  [L,N] = BWLABEL(BW) numérote les régions de pixels vrais.
  CONNEXITE vaut 4 ou 8 (8 par défaut).
```

## `edge`

```
EDGE Détection de contours.
  C = EDGE(X) applique Sobel avec un seuil automatique.
  C = EDGE(X,'sobel'|'prewitt'|'log',SEUIL) choisit la méthode.
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

## `graythresh`

```
GRAYTHRESH Seuil global par la méthode d'Otsu.
  SEUIL = GRAYTHRESH(X) maximise la variance interclasse.
```

## `histeq`

```
HISTEQ Égalisation d'histogramme.
```

## `im2double`

```
IM2DOUBLE Convertit une image en double dans [0,1].
```

## `im2uint8`

```
IM2UINT8 Convertit une image en uint8 (0 à 255).
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

## `imclose`

```
IMCLOSE Fermeture morphologique : dilatation puis érosion.
```

## `imcrop`

```
IMCROP Découpe un rectangle [x y largeur hauteur] dans une image.
```

## `imdilate`

```
IMDILATE Dilatation morphologique.
```

## `imerode`

```
IMERODE Érosion morphologique.
```

## `imfilter`

```
IMFILTER Filtrage linéaire d'une image par corrélation.
  Y = IMFILTER(X,H) corrèle X avec le noyau H, les bords étant
  répliqués. Y = IMFILTER(X,H,'conv') fait une convolution.

  Le travail est confié à CONV2, qui est natif : l'image est d'abord
  agrandie par réplication des bords, puis filtrée en mode « valid ».
  Un noyau retourné transforme la convolution de CONV2 en corrélation.
```

## `imgaussfilt`

```
IMGAUSSFILT Lissage gaussien d'une image.
```

## `imhist`

```
IMHIST Histogramme d'une image.
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

## `imshow`

```
IMSHOW Affiche une image dans les axes courants.
  Le rendu se fait en SVG : « print » écrit le fichier.
```

## `imwrite`

```
IMWRITE Écrit une image au format PGM (gris) ou PPM (couleur).
  Ces deux formats sont du texte : aucune bibliothèque externe n'est
  nécessaire, et tous les visionneurs les lisent.
```

## `medfilt2`

```
MEDFILT2 Filtre médian bidimensionnel.
```

## `morphologie`

```
MORPHOLOGIE Noyau commun de l'érosion et de la dilatation.
```

## `rgb2gray`

```
RGB2GRAY Luminance d'une image couleur.
  G = RGB2GRAY(RGB) applique la pondération de la recommandation
  ITU-R BT.601 : 0.2989 R + 0.5870 V + 0.1140 B.
```

