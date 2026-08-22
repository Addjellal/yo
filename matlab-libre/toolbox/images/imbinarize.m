function b = imbinarize(x, seuil)
%IMBINARIZE Seuillage d'une image en niveaux de gris.
    x = im2double(x);
    if nargin < 2 || isempty(seuil)
        seuil = graythresh(x);
    end
    b = x > seuil;
end
