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
    % On ramene le nuage dans le carre unite. Une similitude envoie les
    % cercles sur des cercles, donc ne change pas la triangulation ; mais
    % elle rend le determinant du test du cercle comparable a une
    % tolerance fixe, ce qui compte quand les points sont cocycliques.
    etendue = max(max(x) - min(x), max(y) - min(y));
    if etendue == 0
        return;
    end
    x = (x - min(x)) / etendue;
    y = (y - min(y)) / etendue;
    tolerance = 1e-12;

    % Un triangle englobant, tres grand devant le nuage.
    px = [x; -100; 101; 0.5];
    py = [y; -100; -100; 150];
    triangles = [n + 1, n + 2, n + 3];

    for k = 1:n
        mauvais = false(size(triangles, 1), 1);
        for t = 1:size(triangles, 1)
            mauvais(t) = dansCercle(px(triangles(t, :)), py(triangles(t, :)), ...
                                    px(k), py(k), tolerance);
        end
        if ~any(mauvais)
            continue;
        end
        % La cavite doit etre d'un seul tenant et vue entierement depuis le
        % nouveau point : sinon son bord n'est pas un contour simple, et la
        % retriangulation produit des triangles qui se recouvrent. Quand
        % les points sont cocycliques, le test du cercle rend des reponses
        % que l'arrondi decide, et c'est exactement ce qui arrive.
        %
        % On part donc du triangle qui contient le point, et l'on n'ajoute
        % un triangle mauvais que s'il touche la cavite par une arete.
        mauvais = cavite(triangles, mauvais, px, py, k);

        % Le bord du trou : les aretes qui n'appartiennent qu'a un seul
        % des triangles supprimes.
        indices = find(mauvais);
        aretes = zeros(3 * numel(indices), 2);
        for i = 1:numel(indices)
            s = triangles(indices(i), :);
            aretes(3*i-2:3*i, :) = [s(1) s(2); s(2) s(3); s(3) s(1)];
        end
        [~, ~, position] = unique(sort(aretes, 2), 'rows');
        compte = accumarray(position(:), 1);
        aretes = aretes(compte(position) == 1, :);

        triangles = triangles(~mauvais, :);
        for a = 1:size(aretes, 1)
            % Une arete vue de profil depuis le point ne fait pas un
            % triangle : on la laisse, plutot que d'ajouter une lamelle
            % d'aire nulle qui fausserait tout ce qui suit.
            aire = (px(aretes(a, 2)) - px(aretes(a, 1))) * (py(k) - py(aretes(a, 1))) - ...
                   (px(k) - px(aretes(a, 1))) * (py(aretes(a, 2)) - py(aretes(a, 1)));
            if abs(aire) > tolerance
                triangles = [triangles; aretes(a, 1), aretes(a, 2), k];   %#ok<AGROW>
            end
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

function garde = cavite(triangles, mauvais, px, py, k)
%CAVITE La partie de la cavite qui touche le point, d'un seul tenant.
%   On part du triangle qui contient le point — a defaut, du premier
%   mauvais —, et l'on n'y agrege un triangle mauvais que s'il partage une
%   arete avec ce qu'on a deja. Ce qui reste dehors n'est pas retire.
    garde = false(size(mauvais));
    depart = 0;
    for t = find(mauvais)'
        if dansTriangle(px(triangles(t, :)), py(triangles(t, :)), px(k), py(k))
            depart = t;
            break;
        end
    end
    if depart == 0
        depart = find(mauvais, 1);
    end
    garde(depart) = true;
    change = true;
    while change
        change = false;
        for t = find(mauvais & ~garde)'
            for u = find(garde)'
                if numel(intersect(triangles(t, :), triangles(u, :))) == 2
                    garde(t) = true;
                    change = true;
                    break;
                end
            end
        end
    end
end

function dedans = dansTriangle(xs, ys, x, y)
%DANSTRIANGLE Le point est-il dans le triangle, bord compris ?
    d1 = (xs(2) - xs(1)) * (y - ys(1)) - (x - xs(1)) * (ys(2) - ys(1));
    d2 = (xs(3) - xs(2)) * (y - ys(2)) - (x - xs(2)) * (ys(3) - ys(2));
    d3 = (xs(1) - xs(3)) * (y - ys(3)) - (x - xs(3)) * (ys(1) - ys(3));
    dedans = (d1 >= 0 && d2 >= 0 && d3 >= 0) || (d1 <= 0 && d2 <= 0 && d3 <= 0);
end

function dedans = dansCercle(xs, ys, x, y, tolerance)
%DANSCERCLE Le point est-il strictement dans le cercle circonscrit ?
%   Le determinant classique : positif quand le point est a l'interieur,
%   les sommets etant donnes dans le sens direct. Un point pose sur le
%   cercle rend zero, et compte comme dehors : c'est la seule facon de
%   traiter les points cocycliques sans que l'arrondi decide a notre
%   place, chaque triangle d'un cote different.
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
    dedans = determinant > tolerance;
end
