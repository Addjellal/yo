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
