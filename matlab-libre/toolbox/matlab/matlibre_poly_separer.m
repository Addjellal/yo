function contours = matlibre_poly_separer(V)
%MATLIBRE_POLY_SEPARER Découpe une liste de sommets sur les NaN.
%   Un NaN sépare deux contours. Les contours de moins de trois sommets
%   sont écartés : ils n'enferment rien.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
%
%   Exemple :
%      c = matlibre_poly_separer([0 0; 1 0; 1 1; NaN NaN; 2 2; 3 2; 3 3]);
%      numel(c)                        % 2 contours
%
%   Voir aussi POLYSHAPE, MATLIBRE_POLY_ASSEMBLER.
    contours = {};
    if isempty(V)
        return
    end
    V = double(V);
    coupures = [0; find(isnan(V(:, 1))); size(V, 1) + 1];
    for k = 1:numel(coupures) - 1
        morceau = V(coupures(k) + 1 : coupures(k + 1) - 1, :);
        if size(morceau, 1) >= 3
            contours{end + 1} = morceau;   %#ok<AGROW>
        end
    end
end
