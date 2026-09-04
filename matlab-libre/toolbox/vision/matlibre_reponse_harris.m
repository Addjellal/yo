function R = matlibre_reponse_harris(I, constante)
%MATLIBRE_REPONSE_HARRIS Carte de réponse du détecteur de Harris.
%   R = MATLIBRE_REPONSE_HARRIS(I) rend, en chaque pixel, le déterminant
%   moins CONSTANTE fois le carré de la trace de la matrice des moments du
%   gradient, lissée par une gaussienne. La réponse est grande là où le
%   gradient change de direction — un coin — et faible le long d'un
%   contour, où il ne change pas.
%
%   R = MATLIBRE_REPONSE_HARRIS(I,CONSTANTE) impose la constante, 0,04 par
%   défaut.
%
%   Exemple :
%      I = zeros(21); I(1:10, 1:10) = 1;
%      R = matlibre_reponse_harris(I);
%      R(10, 10) > 0     % le coin du carré répond
%
%   Voir aussi DETECTHARRISFEATURES, DETECTORBFEATURES.
    if nargin < 2
        constante = 0.04;
    end
    I = double(I);
    if ndims(I) == 3
        I = rgb2gray(I);
    end
    hx = [1 0 -1; 2 0 -2; 1 0 -1] / 8;
    Ix = imfilter(I, hx);
    Iy = imfilter(I, hx.');
    lissage = fspecial('gaussian', 5, 1);
    Sxx = imfilter(Ix .* Ix, lissage);
    Syy = imfilter(Iy .* Iy, lissage);
    Sxy = imfilter(Ix .* Iy, lissage);
    R = (Sxx .* Syy - Sxy .^ 2) - constante * (Sxx + Syy) .^ 2;
end
