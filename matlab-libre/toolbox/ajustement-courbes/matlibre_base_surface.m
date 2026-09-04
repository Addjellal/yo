function A = matlibre_base_surface(xy, puissances)
%MATLIBRE_BASE_SURFACE Matrice de conception d'un polynôme de surface.
%   A = MATLIBRE_BASE_SURFACE(XY,PUISSANCES) où XY a deux colonnes rend la
%   matrice dont la colonne k porte x^a * y^b pour le k-ième couple
%   d'exposants.
%
%   Exemple :
%      matlibre_base_surface([2 3], [0 0; 1 0; 0 1])      % 1 2 3
%
%   Voir aussi MATLIBRE_MODELE_SURFACE, FIT.
    xy = double(xy);
    if size(xy, 2) ~= 2
        xy = reshape(xy, [], 2);
    end
    x = xy(:, 1);
    y = xy(:, 2);
    A = zeros(numel(x), size(puissances, 1));
    for k = 1:size(puissances, 1)
        A(:, k) = x .^ puissances(k, 1) .* y .^ puissances(k, 2);
    end
end
