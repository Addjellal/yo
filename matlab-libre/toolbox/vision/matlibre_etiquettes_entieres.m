function L = matlibre_etiquettes_entieres(entree)
%MATLIBRE_ETIQUETTES_ENTIERES Matrice d'étiquettes à partir de ce qu'on a.
%   L = MATLIBRE_ETIQUETTES_ENTIERES(E) accepte une matrice d'entiers, un
%   masque logique ou un tableau catégoriel, et rend une matrice d'entiers
%   où zéro est le fond.
%
%   Exemple :
%      matlibre_etiquettes_entieres(logical([0 1; 1 0]))
%
%   Voir aussi LABELOVERLAY, SUPERPIXELS.
    if islogical(entree)
        L = double(entree);
    elseif iscategorical(entree)
        % Les catégories sont numérotées dans l'ordre de leur liste ;
        % les valeurs manquantes deviennent le fond.
        codes = double(entree);
        codes(isnan(codes)) = 0;
        L = codes;
    else
        L = round(double(entree));
        L(L < 0) = 0;
    end
end
