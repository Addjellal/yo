function T = delaunay(x, y)
%DELAUNAY Triangulation de Delaunay.
%   T = DELAUNAY(X,Y) rend la triangulation de Delaunay des points
%   (X,Y) : une ligne par triangle, portant les indices de ses trois
%   sommets. C'est la triangulation dont aucun cercle circonscrit ne
%   contient de point ; c'est elle qui évite au mieux les triangles
%   étirés, ce qui la rend bonne pour l'interpolation et le maillage.
%
%   T = DELAUNAY(P) où P a deux colonnes fait la même chose.
%
%   La construction est celle de Bowyer et Watson : on part d'un grand
%   triangle qui contient tout, on insère les points un à un en
%   supprimant les triangles dont le cercle circonscrit contient le
%   nouveau point, et on retriangule le trou ainsi créé.
%
%   Trois points alignés ne forment pas de triangle ; s'ils le sont tous,
%   la triangulation est vide.
%
%   Exemples :
%      x = rand(20, 1); y = rand(20, 1);
%      T = delaunay(x, y);
%      trimesh(T, x, y);
%
%      T = delaunay([0 1 1 0], [0 0 1 1])     % deux triangles
%
%   Voir aussi TRIMESH, TRISURF, VORONOI, CONVHULL, GRIDDATA.
    if nargin < 2
        y = x(:, 2);
        x = x(:, 1);
    end
    x = double(x(:));
    y = double(y(:));
    n = numel(x);
    T = zeros(0, 3);
    if n < 3
        return;
    end
    % Un triangle englobant, tres grand devant le nuage.
    milieuX = (max(x) + min(x)) / 2;
    milieuY = (max(y) + min(y)) / 2;
    rayon = max(max(x) - min(x), max(y) - min(y));
    if rayon == 0
        return;
    end
    rayon = rayon * 100;
    px = [x; milieuX - rayon; milieuX + rayon; milieuX];
    py = [y; milieuY - rayon; milieuY - rayon; milieuY + rayon];
    triangles = [n + 1, n + 2, n + 3];

    for k = 1:n
        % Les triangles dont le cercle circonscrit contient le point.
        mauvais = false(size(triangles, 1), 1);
        for t = 1:size(triangles, 1)
            mauvais(t) = dansCercle(px(triangles(t, :)), py(triangles(t, :)), ...
                                    px(k), py(k));
        end
        if ~any(mauvais)
            continue;
        end
        % Le bord du trou : les aretes qui n'appartiennent qu'a un seul
        % des triangles supprimes.
        aretes = [];
        indices = find(mauvais);
        for t = indices'
            s = triangles(t, :);
            aretes = [aretes; s(1) s(2); s(2) s(3); s(3) s(1)];   %#ok<AGROW>
        end
        garde = true(size(aretes, 1), 1);
        for a = 1:size(aretes, 1)
            for b = a + 1:size(aretes, 1)
                if (aretes(a, 1) == aretes(b, 2) && aretes(a, 2) == aretes(b, 1)) || ...
                   (aretes(a, 1) == aretes(b, 1) && aretes(a, 2) == aretes(b, 2))
                    garde(a) = false;
                    garde(b) = false;
                end
            end
        end
        aretes = aretes(garde, :);
        triangles = triangles(~mauvais, :);
        for a = 1:size(aretes, 1)
            triangles = [triangles; aretes(a, 1), aretes(a, 2), k];   %#ok<AGROW>
        end
    end

    % On jette les triangles qui touchent encore le triangle englobant.
    garde = all(triangles <= n, 2);
    triangles = triangles(garde, :);
    % Les sommets dans le sens direct, comme MATLAB les rend.
    for t = 1:size(triangles, 1)
        s = triangles(t, :);
        aire = (px(s(2)) - px(s(1))) * (py(s(3)) - py(s(1))) - ...
               (px(s(3)) - px(s(1))) * (py(s(2)) - py(s(1)));
        if aire < 0
            triangles(t, :) = s([1 3 2]);
        end
    end
    T = triangles;
end

function dedans = dansCercle(xs, ys, x, y)
%DANSCERCLE Le point est-il dans le cercle circonscrit au triangle ?
%   Le determinant classique : positif quand le point est a l'interieur,
%   les sommets etant donnes dans le sens direct.
    aire = (xs(2) - xs(1)) * (ys(3) - ys(1)) - (xs(3) - xs(1)) * (ys(2) - ys(1));
    if aire == 0
        dedans = false;
        return;
    end
    if aire < 0
        xs = xs([1 3 2]);
        ys = ys([1 3 2]);
    end
    ax = xs(1) - x; ay = ys(1) - y;
    bx = xs(2) - x; by = ys(2) - y;
    cx = xs(3) - x; cy = ys(3) - y;
    determinant = (ax * ax + ay * ay) * (bx * cy - cx * by) - ...
                  (bx * bx + by * by) * (ax * cy - cx * ay) + ...
                  (cx * cx + cy * cy) * (ax * by - bx * ay);
    dedans = determinant > 0;
end
