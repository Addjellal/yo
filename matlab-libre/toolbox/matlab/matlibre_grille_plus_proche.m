function vq = matlibre_grille_plus_proche(x, y, v, xq, yq)
%MATLIBRE_GRILLE_PLUS_PROCHE Valeur du point de données le plus proche.
%   VQ = MATLIBRE_GRILLE_PLUS_PROCHE(X,Y,V,XQ,YQ) rend, pour chaque point
%   demandé, la valeur du point de données dont il est le plus près.
%
%   Exemple :
%      matlibre_grille_plus_proche([0;1], [0;0], [10;20], 0.9, 0)      % 20
%
%   Voir aussi GRIDDATA.
    vq = zeros(numel(xq), 1);
    for k = 1:numel(xq)
        [~, position] = min((x - xq(k)) .^ 2 + (y - yq(k)) .^ 2);
        vq(k) = v(position);
    end
end
