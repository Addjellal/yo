function g = im2gray(image)
%IM2GRAY Rend une image en niveaux de gris, quelle que soit l'entrée.
%   Une image déjà en niveaux de gris ressort inchangée.
%
%   Exemple :
%      max(abs(im2gray(reshape([0.2 0.4 0.6], 1, 1, 3)) - rgb2gray(reshape([0.2 0.4 0.6], 1, 1, 3)))) < 1e-12
%      isequal(im2gray(rand(4)), im2gray(rand(4)) * 1)   % une image grise passe telle quelle
    if ndims(image) == 3 && size(image, 3) == 3
        g = rgb2gray(image);
    else
        g = image;
    end
end
