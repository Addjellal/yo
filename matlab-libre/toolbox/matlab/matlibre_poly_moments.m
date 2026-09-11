function [aire, cx, cy] = matlibre_poly_moments(C)
%MATLIBRE_POLY_MOMENTS Aire signée et centre de gravité d'un contour.
%   Le centre de gravité d'une surface polygonale s'obtient de la même
%   somme que son aire : chaque côté contribue par le produit croisé de
%   ses deux extrémités, pondéré par leur somme. C'est l'intégrale de x
%   sur la surface, ramenée au bord par la formule de Green.
%
%   L'aire rendue garde son signe, ce qui permet à un trou de contribuer
%   en négatif et de déplacer le centre du bon côté.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
%
%   Exemple :
%      [a, x, y] = matlibre_poly_moments([0 0; 2 0; 2 2; 0 2]);
%      abs(a - 4) < 1e-12 && abs(x - 1) < 1e-12 && abs(y - 1) < 1e-12
%
%   Voir aussi CENTROID, POLYAREA, POLYSHAPE.
    x = C(:, 1);
    y = C(:, 2);
    xs = x([2:end 1]);
    ys = y([2:end 1]);
    croix = x .* ys - xs .* y;
    aire = sum(croix) / 2;
    if abs(aire) < eps
        cx = mean(x);
        cy = mean(y);
        return
    end
    cx = sum((x + xs) .* croix) / (6 * aire);
    cy = sum((y + ys) .* croix) / (6 * aire);
end
