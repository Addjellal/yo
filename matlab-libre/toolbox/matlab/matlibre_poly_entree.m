function contours = matlibre_poly_entree(arguments)
%MATLIBRE_POLY_ENTREE Démêle les arguments d'un POLYSHAPE.
%   Accepte une matrice à deux colonnes, deux vecteurs de coordonnées, ou
%   deux cellules de vecteurs — un contour par élément. Les contours
%   séparés par des NaN sont découpés.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
%
%   Exemple :
%      c = matlibre_poly_entree({[0 1 1 0], [0 0 1 1]});
%      size(c{1})                      % 4 sommets, 2 colonnes
%
%   Voir aussi POLYSHAPE.
    contours = {};
    if isempty(arguments)
        return
    end
    premier = arguments{1};
    if iscell(premier)
        for k = 1:numel(premier)
            x = double(premier{k}(:));
            y = double(arguments{2}{k}(:));
            contours = [contours, matlibre_poly_separer([x, y])];   %#ok<AGROW>
        end
        return
    end
    if numel(arguments) >= 2 && isnumeric(arguments{2}) && ...
            numel(arguments{2}) == numel(premier)
        P = [double(premier(:)), double(arguments{2}(:))];
    else
        P = double(premier);
        if size(P, 2) ~= 2
            error('MATLAB:polyshape:forme', ...
                  'Les sommets s''écrivent en deux colonnes.');
        end
    end
    contours = matlibre_poly_separer(P);
end
