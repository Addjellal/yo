function y = matlibre_regression_locale(xd, yd, x, portee, degre)
%MATLIBRE_REGRESSION_LOCALE Lissage par régression locale pondérée.
%   Y = MATLIBRE_REGRESSION_LOCALE(XD,YD,X,PORTEE,DEGRE) ajuste, autour de
%   chaque point où l'on veut la courbe, un polynôme de degré DEGRE aux
%   points voisins, pondérés par la fonction tricube de leur distance.
%
%   PORTEE est la part des points que voit chaque ajustement local : plus
%   elle est grande, plus la courbe est lisse. La pondération tricube
%   s'annule au bord du voisinage, ce qui évite les sauts quand un point
%   entre ou sort.
%
%   Exemple :
%      x = (1:20)';
%      matlibre_regression_locale(x, x.^2, [5; 10], 0.5, 1);
%
%   Voir aussi SMOOTH, FIT.
    xd = xd(:);
    yd = yd(:);
    x = x(:);
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
        poids = (1 - min(u, 1) .^ 3) .^ 3;
        A = matlibre_base_polynome(xd(choisis) - x(k), degre);
        racine = sqrt(poids);
        coefficients = (A .* racine) \ (yd(choisis) .* racine);
        % Le polynôme est écrit en l'écart au point visé : sa valeur là
        % est donc son terme constant, le dernier de la base.
        y(k) = coefficients(end);
    end
end
