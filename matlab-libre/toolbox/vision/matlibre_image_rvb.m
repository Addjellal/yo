function [J, classe] = matlibre_image_rvb(I)
%MATLIBRE_IMAGE_RVB Image en trois plans, valeurs dans [0,1].
%   [J,CLASSE] = MATLIBRE_IMAGE_RVB(I) rend l'image en couleurs et en
%   flottant, ainsi que la classe de départ pour pouvoir y revenir. Une
%   image en niveaux de gris est recopiée sur les trois plans ; une image
%   entière est divisée par sa valeur maximale.
%
%   Exemple :
%      [J, c] = matlibre_image_rvb(uint8(zeros(4, 4)));
%      size(J)   % 4 4 3
%
%   Voir aussi MATLIBRE_IMAGE_CLASSE, INSERTTEXT.
    classe = class(I);
    J = double(I);
    switch classe
        case 'uint8',  J = J / 255;
        case 'uint16', J = J / 65535;
        case 'int16',  J = (J + 32768) / 65535;
        case 'logical', J = double(J);
    end
    if ndims(J) == 2
        J = repmat(J, [1 1 3]);
    elseif size(J, 3) == 1
        J = repmat(J, [1 1 3]);
    end
end
