function [Vx, Vy] = voronoi(x, y, T)
%VORONOI Diagramme de Voronoï.
%   VORONOI(X,Y) trace le diagramme de Voronoï des points (X,Y) : le plan
%   découpé en régions, une par point, chaque région rassemblant ce qui
%   est plus proche de ce point que de tout autre.
%
%   VORONOI(X,Y,T) emploie la triangulation T plutôt que de la calculer.
%
%   [VX,VY] = VORONOI(...) rend les arêtes sans rien tracer : chaque
%   colonne porte les deux extrémités d'une arête.
%
%   Le diagramme est le dual de la triangulation de Delaunay : à chaque
%   arête de Delaunay entre deux points correspond une arête de Voronoï
%   qui joint les centres des cercles circonscrits des deux triangles
%   adjacents. Les arêtes du bord, qui n'ont qu'un triangle, partent vers
%   l'infini ; MatLibre les tronque au cadre du dessin.
%
%   Exemples :
%      x = rand(20, 1); y = rand(20, 1);
%      voronoi(x, y);
%
%      voronoi([0 1 1 0 0.5], [0 0 1 1 0.5]);
%
%   Voir aussi DELAUNAY, TRIMESH, CONVHULL, PDIST2, KNNSEARCH.
    x = double(x(:));
    y = double(y(:));
    if nargin < 3 || isempty(T)
        T = delaunay(x, y);
    end
    n = size(T, 1);
    % Le centre du cercle circonscrit de chaque triangle.
    centres = zeros(n, 2);
    for t = 1:n
        centres(t, :) = centreCirconscrit(x(T(t, :)), y(T(t, :)));
    end
    % Les aretes de Delaunay, et les triangles qui les portent.
    aretes = [];
    porteurs = [];
    for t = 1:n
        s = T(t, :);
        for paire = [1 2; 2 3; 3 1]'
            a = min(s(paire(1)), s(paire(2)));
            b = max(s(paire(1)), s(paire(2)));
            rang = 0;
            for r = 1:size(aretes, 1)
                if aretes(r, 1) == a && aretes(r, 2) == b
                    rang = r;
                    break;
                end
            end
            if rang == 0
                aretes = [aretes; a b];            %#ok<AGROW>
                porteurs = [porteurs; t 0];        %#ok<AGROW>
            else
                porteurs(rang, 2) = t;
            end
        end
    end

    etendue = max(max(x) - min(x), max(y) - min(y));
    if etendue == 0
        etendue = 1;
    end
    Vx = [];
    Vy = [];
    for r = 1:size(aretes, 1)
        t1 = porteurs(r, 1);
        t2 = porteurs(r, 2);
        if t2 > 0
            Vx = [Vx, [centres(t1, 1); centres(t2, 1)]];    %#ok<AGROW>
            Vy = [Vy, [centres(t1, 2); centres(t2, 2)]];    %#ok<AGROW>
        else
            % Arete de bord : la demi-droite qui part du centre, dans la
            % direction perpendiculaire a l'arete de Delaunay et vers
            % l'exterieur du triangle.
            a = aretes(r, 1);
            b = aretes(r, 2);
            milieuX = (x(a) + x(b)) / 2;
            milieuY = (y(a) + y(b)) / 2;
            dx = milieuX - centres(t1, 1);
            dy = milieuY - centres(t1, 2);
            longueur = sqrt(dx ^ 2 + dy ^ 2);
            if longueur == 0
                % Le centre est sur l'arete : on prend la perpendiculaire.
                dx = -(y(b) - y(a));
                dy = x(b) - x(a);
                longueur = sqrt(dx ^ 2 + dy ^ 2);
            end
            if longueur == 0
                continue;
            end
            Vx = [Vx, [centres(t1, 1); centres(t1, 1) + etendue * dx / longueur]];  %#ok<AGROW>
            Vy = [Vy, [centres(t1, 2); centres(t1, 2) + etendue * dy / longueur]];  %#ok<AGROW>
        end
    end
    if nargout == 0
        aEffacer = ishold();
        if ~aEffacer
            cla;
        end
        hold('on');
        plot(x, y, 'r.');
        for k = 1:size(Vx, 2)
            plot(Vx(:, k), Vy(:, k), 'b-');
        end
        if ~aEffacer
            hold('off');
        end
        xlim([min(x) - 0.2 * etendue, max(x) + 0.2 * etendue]);
        ylim([min(y) - 0.2 * etendue, max(y) + 0.2 * etendue]);
        clear Vx;
    end
end

function c = centreCirconscrit(xs, ys)
%CENTRECIRCONSCRIT Le centre du cercle passant par les trois sommets.
    ax = xs(1); ay = ys(1);
    bx = xs(2); by = ys(2);
    cx = xs(3); cy = ys(3);
    d = 2 * (ax * (by - cy) + bx * (cy - ay) + cx * (ay - by));
    if d == 0
        c = [mean(xs), mean(ys)];
        return;
    end
    ux = ((ax ^ 2 + ay ^ 2) * (by - cy) + (bx ^ 2 + by ^ 2) * (cy - ay) + ...
          (cx ^ 2 + cy ^ 2) * (ay - by)) / d;
    uy = ((ax ^ 2 + ay ^ 2) * (cx - bx) + (bx ^ 2 + by ^ 2) * (ax - cx) + ...
          (cx ^ 2 + cy ^ 2) * (bx - ax)) / d;
    c = [ux, uy];
end
