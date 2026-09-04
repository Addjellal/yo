function c = matlibre_dl_couple(valeur)
%MATLIBRE_DL_COUPLE Un réglage donné pour les deux dimensions spatiales.
%   C = MATLIBRE_DL_COUPLE(V) rend un couple : un nombre unique vaut pour
%   les deux dimensions, un couple est rendu tel quel.
%
%   Exemple :
%      matlibre_dl_couple(2)     % 2 2
%
%   Voir aussi DLCONV.
    valeur = double(valeur);
    if isscalar(valeur)
        c = [valeur, valeur];
    else
        c = reshape(valeur(1:2), 1, 2);
    end
end
