function distances = matlibre_distance_voisins(points, voisins)
%MATLIBRE_DISTANCE_VOISINS Distance moyenne de chaque point à ses plus proches.
%   Le calcul est fait par blocs : la matrice de toutes les distances
%   deux à deux tiendrait mal en mémoire au-delà de quelques milliers de
%   points, mais un bloc de lignes tient toujours.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
    n = size(points, 1);
    voisins = min(max(voisins, 1), n - 1);
    distances = zeros(n, 1);
    bloc = max(min(4096, floor(4e6 / max(n, 1))), 1);
    normes = sum(points .^ 2, 2);
    for debut = 1:bloc:n
        fin = min(debut + bloc - 1, n);
        morceau = points(debut:fin, :);
        carres = repmat(sum(morceau .^ 2, 2), 1, n) + repmat(normes.', fin - debut + 1, 1) ...
                 - 2 * (morceau * points.');
        carres = max(carres, 0);
        triees = sort(carres, 2);
        % La première colonne est la distance du point à lui-même.
        distances(debut:fin) = mean(sqrt(triees(:, 2:(voisins + 1))), 2);
    end
end
