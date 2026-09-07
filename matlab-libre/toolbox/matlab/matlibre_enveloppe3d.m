function F = matlibre_enveloppe3d(P)
%MATLIBRE_ENVELOPPE3D Facettes de l'enveloppe convexe d'un nuage de l'espace.
%   La construction est incrémentale. On part d'un tétraèdre formé de
%   quatre points non coplanaires, puis on ajoute les points un à un :
%   celui qui est à l'extérieur voit certaines facettes — celles dont il
%   est du côté de la normale —, on les retire, et le trou laissé est un
%   contour fermé, l'horizon, que l'on referme en reliant chacune de ses
%   arêtes au nouveau point.
%
%   Un point posé exactement sur le plan d'une facette ne la voit pas : il
%   ne change donc rien à l'enveloppe, ce qui est juste, et c'est ainsi
%   que les points coplanaires — les quatre coins d'une face de cube — ne
%   produisent pas de facettes qui se recouvrent.
%
%   Chaque facette est orientée vers l'extérieur.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
%
%   Exemple :
%      F = matlibre_enveloppe3d([0 0 0; 1 0 0; 0 1 0; 0 0 1]);
%      size(F, 1)                      % 4 : le tetraedre a quatre faces
%
%   Voir aussi CONVHULLN, CONVHULL.
    P = double(P);
    n = size(P, 1);
    echelle = max(1, max(abs(P(:))));
    tolerance = 1e-12 * echelle;

    depart = tetraedreDepart(P, tolerance);
    if isempty(depart)
        F = zeros(0, 3);         % tous les points sont coplanaires
        return
    end
    F = [depart([1 2 3]); depart([1 2 4]); depart([1 3 4]); depart([2 3 4])];
    interieur = mean(P(depart, :), 1);
    for f = 1:4
        F(f, :) = orienter(P, F(f, :), interieur);
    end

    for p = 1:n
        if any(depart == p)
            continue
        end
        vues = false(size(F, 1), 1);
        for f = 1:size(F, 1)
            vues(f) = distanceSignee(P, F(f, :), P(p, :)) > tolerance;
        end
        if ~any(vues)
            continue                  % le point est dedans, ou sur le bord
        end
        % L'horizon : les aretes des facettes vues qui ne sont pas
        % partagees avec une autre facette vue. Ce sont elles qui bordent
        % le trou, et c'est a elles qu'on raccroche le nouveau point.
        indices = find(vues);
        aretes = zeros(0, 2);
        for k = 1:numel(indices)
            t = F(indices(k), :);
            aretes = [aretes; t([1 2]); t([2 3]); t([3 1])];   %#ok<AGROW>
        end
        triees = sort(aretes, 2);
        [~, ~, position] = unique(triees, 'rows');
        compte = accumarray(position(:), 1);
        horizon = aretes(compte(position) == 1, :);
        F(vues, :) = [];
        for k = 1:size(horizon, 1)
            F(end + 1, :) = [horizon(k, :), p];   %#ok<AGROW>
        end
    end
end

function d = distanceSignee(P, facette, point)
% Positive du cote ou la facette regarde.
    a = P(facette(1), :);
    normale = cross(P(facette(2), :) - a, P(facette(3), :) - a);
    longueur = norm(normale);
    if longueur == 0
        d = 0;
    else
        d = dot(point - a, normale) / longueur;
    end
end

function f = orienter(P, facette, interieur)
% La normale doit pointer a l'oppose de l'interieur.
    if distanceSignee(P, facette, interieur) > 0
        f = facette([1 3 2]);
    else
        f = facette;
    end
end

function s = tetraedreDepart(P, tolerance)
% Quatre points non coplanaires : les deux plus eloignes, puis le plus
% loin de leur droite, puis le plus loin de leur plan.
    n = size(P, 1);
    s = [];
    [~, i] = min(P(:, 1));
    [~, j] = max(P(:, 1));
    if i == j
        return
    end
    direction = P(j, :) - P(i, :);
    meilleur = 0; k = 0;
    for c = 1:n
        ecart = norm(cross(direction, P(c, :) - P(i, :)));
        if ecart > meilleur
            meilleur = ecart; k = c;
        end
    end
    if k == 0 || meilleur <= tolerance
        return
    end
    normale = cross(direction, P(k, :) - P(i, :));
    normale = normale / norm(normale);
    meilleur = 0; l = 0;
    for c = 1:n
        ecart = abs(dot(P(c, :) - P(i, :), normale));
        if ecart > meilleur
            meilleur = ecart; l = c;
        end
    end
    if l == 0 || meilleur <= tolerance
        return
    end
    s = [i j k l];
end
