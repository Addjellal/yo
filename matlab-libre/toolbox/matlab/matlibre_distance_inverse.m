function vq = matlibre_distance_inverse(x, y, v, xq, yq)
%MATLIBRE_DISTANCE_INVERSE Moyenne pondérée par l'inverse du carré de la distance.
%   VQ = MATLIBRE_DISTANCE_INVERSE(X,Y,V,XQ,YQ) rend, en chaque point
%   demandé, la moyenne des valeurs pondérée par l'inverse du carré de la
%   distance. La surface obtenue passe par les points de données et est
%   définie partout.
%
%   Exemple :
%      matlibre_distance_inverse([0;1], [0;0], [0;1], 0.5, 0)      % 0.5
%
%   Voir aussi GRIDDATA.
    vq = zeros(numel(xq), 1);
    for k = 1:numel(xq)
        carres = (x - xq(k)) .^ 2 + (y - yq(k)) .^ 2;
        exact = find(carres == 0, 1);
        if ~isempty(exact)
            vq(k) = v(exact);
            continue
        end
        poids = 1 ./ carres;
        vq(k) = sum(poids .* v) / sum(poids);
    end
end
