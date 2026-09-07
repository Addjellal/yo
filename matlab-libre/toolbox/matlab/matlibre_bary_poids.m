function poids = matlibre_bary_poids(sommets, point)
%MATLIBRE_BARY_POIDS Coordonnées barycentriques d'un point dans un triangle.
%   Les trois poids somment à un et sont tous positifs précisément quand
%   le point est dans le triangle, bord compris. C'est le test
%   d'appartenance le plus sûr : il ne dépend pas de l'orientation.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
%
%   Exemple :
%      p = matlibre_bary_poids([0 0; 1 0; 0 1], [0.25 0.25]);
%      abs(sum(p) - 1) < 1e-12
%
%   Voir aussi DELAUNAYTRIANGULATION, TRIANGULATION, INPOLYGON.
    a = sommets(1, :); b = sommets(2, :); c = sommets(3, :);
    aire = (b(1) - a(1)) * (c(2) - a(2)) - (c(1) - a(1)) * (b(2) - a(2));
    if abs(aire) < eps
        poids = [NaN NaN NaN];
        return
    end
    l1 = ((b(1) - point(1)) * (c(2) - point(2)) - ...
          (c(1) - point(1)) * (b(2) - point(2))) / aire;
    l2 = ((c(1) - point(1)) * (a(2) - point(2)) - ...
          (a(1) - point(1)) * (c(2) - point(2))) / aire;
    poids = [l1, l2, 1 - l1 - l2];
end
