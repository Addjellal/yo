function z = matlibre_regression_locale_surface(xyd, zd, xy, portee, degre)
%MATLIBRE_REGRESSION_LOCALE_SURFACE Lissage local d'une surface.
%   Z = MATLIBRE_REGRESSION_LOCALE_SURFACE(XYD,ZD,XY,PORTEE,DEGRE) ajuste,
%   autour de chaque point demandé, un plan ou une quadrique aux voisins
%   les plus proches, pondérés par la tricube de leur distance.
%
%   Exemple :
%      [x, y] = meshgrid(0:0.25:1, 0:0.25:1);
%      matlibre_regression_locale_surface([x(:) y(:)], x(:), [0.5 0.5], 0.5, 1);
%
%   Voir aussi MATLIBRE_EVALUER_SURFACE, FIT.
    n = size(xyd, 1);
    voisins = max(6 * degre, min(n, round(portee * n)));
    z = zeros(size(xy, 1), 1);
    for k = 1:size(xy, 1)
        ecarts = xyd - repmat(xy(k, :), n, 1);
        distances = sqrt(sum(ecarts .^ 2, 2));
        [triees, ordre] = sort(distances);
        choisis = ordre(1:voisins);
        rayon = triees(voisins);
        if rayon <= 0
            z(k) = mean(zd(choisis));
            continue
        end
        u = distances(choisis) / rayon;
        poids = (1 - min(u, 1) .^ 3) .^ 3;
        locaux = ecarts(choisis, :);
        [puissances, ~] = matlibre_termes_surface(degre, degre);
        A = matlibre_base_surface(locaux, puissances);
        racine = sqrt(poids);
        coefficients = (A .* racine) \ (zd(choisis) .* racine);
        % Le modèle est écrit en l'écart au point visé : sa valeur là est
        % le terme constant, premier de la liste des termes.
        z(k) = coefficients(1);
    end
end
