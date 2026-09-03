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
