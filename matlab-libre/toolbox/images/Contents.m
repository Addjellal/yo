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
