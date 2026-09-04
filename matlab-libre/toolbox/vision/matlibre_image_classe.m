function J = matlibre_image_classe(I, classe)
%MATLIBRE_IMAGE_CLASSE Ramène une image de [0,1] vers sa classe d'origine.
%   J = MATLIBRE_IMAGE_CLASSE(I,CLASSE) est l'opération inverse de
%   MATLIBRE_IMAGE_RVB : elle remultiplie et convertit. Une image déjà en
%   double ou en single est rendue telle quelle, bornée à [0,1].
%
%   Exemple :
%      matlibre_image_classe(0.5, 'uint8')   % 128
%
%   Voir aussi MATLIBRE_IMAGE_RVB.
    I = min(max(I, 0), 1);
    switch classe
        case 'uint8',   J = uint8(round(I * 255));
        case 'uint16',  J = uint16(round(I * 65535));
        case 'int16',   J = int16(round(I * 65535) - 32768);
        case 'single',  J = single(I);
        otherwise,      J = I;
    end
end
