function g = im2gray(image)
%IM2GRAY Rend une image en niveaux de gris, quelle que soit l'entrée.
%   Une image déjà en niveaux de gris ressort inchangée.
    if ndims(image) == 3 && size(image, 3) == 3
        g = rgb2gray(image);
    else
        g = image;
    end
end
