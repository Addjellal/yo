function y = matlibre_regression_locale_ponderee(xd, yd, x, portee, degre, poidsPoints)
%MATLIBRE_REGRESSION_LOCALE_PONDEREE Régression locale à poids imposés.
%   Y = MATLIBRE_REGRESSION_LOCALE_PONDEREE(XD,YD,X,PORTEE,DEGRE,POIDS)
%   fait comme MATLIBRE_REGRESSION_LOCALE, mais multiplie la pondération
%   de distance par un poids propre à chaque point : c'est ainsi qu'un
%   lissage robuste écarte les valeurs aberrantes.
%
%   Exemple :
%      x = (1:10)';
%      matlibre_regression_locale_ponderee(x, x, x, 0.5, 1, ones(10, 1));
%
%   Voir aussi MATLIBRE_LISSAGE_LOCAL, SMOOTH.
    xd = xd(:);
    yd = yd(:);
    x = x(:);
    poidsPoints = poidsPoints(:);
    n = numel(xd);
    voisins = max(degre + 1, min(n, round(portee * n)));
    y = zeros(size(x));
    for k = 1:numel(x)
        distances = abs(xd - x(k));
        [triees, ordre] = sort(distances);
        choisis = ordre(1:voisins);
        rayon = triees(voisins);
        if rayon <= 0
            y(k) = mean(yd(choisis));
            continue
        end
        u = distances(choisis) / rayon;
        poids = (1 - min(u, 1) .^ 3) .^ 3 .* poidsPoints(choisis);
        if sum(poids) <= 0
            y(k) = mean(yd(choisis));
            continue
        end
        A = matlibre_base_polynome(xd(choisis) - x(k), degre);
        racine = sqrt(poids);
        coefficients = (A .* racine) \ (yd(choisis) .* racine);
        y(k) = coefficients(end);
    end
end
