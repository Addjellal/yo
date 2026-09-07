classdef alphaShape
%ALPHASHAPE Forme alpha d'un nuage de points du plan.
%   SHP = ALPHASHAPE(X,Y) construit la forme alpha des points, avec un
%   rayon choisi tout seul. SHP = ALPHASHAPE(X,Y,ALPHA) impose le rayon.
%   SHP = ALPHASHAPE(P,...) où P a deux colonnes fait la même chose.
%
%   Une forme alpha est ce qu'on obtient en triangulant le nuage, puis en
%   retirant les triangles dont le cercle circonscrit dépasse le rayon
%   ALPHA. Elle interpole entre le nuage lui-même — ALPHA nul, plus rien
%   ne reste — et son enveloppe convexe — ALPHA infini, tout reste. Entre
%   les deux, elle épouse le nuage, et peut y creuser des baies et des
%   trous que l'enveloppe convexe ne voit pas.
%
%   Ce qu'on lui demande : AREA, PERIMETER, BOUNDARYFACETS, INSHAPE,
%   ALPHATRIANGULATION, CRITICALALPHA, NUMREGIONS.
%
%   Exemple :
%      t = linspace(0, 2*pi, 41)'; t(end) = [];
%      shp = alphaShape(cos(t), sin(t), 2);
%      abs(area(shp) - polyarea(cos(t), sin(t))) < 1e-9
%      inShape(shp, 0, 0)              % 1 : le centre est dedans
%
%   Voir aussi BOUNDARY, CONVHULL, DELAUNAY, POLYAREA.
    properties
        Points = zeros(0, 2)
        Alpha = inf
    end

    methods
        function shp = alphaShape(x, y, alpha)
            if nargin == 0
                return
            end
            if nargin == 1 || (nargin >= 2 && isscalar(y) && size(x, 2) == 2)
                if nargin >= 2, alpha = y; end
                P = double(x);
            else
                P = [double(x(:)), double(y(:))];
            end
            shp.Points = P;
            if exist('alpha', 'var') && ~isempty(alpha)
                shp.Alpha = double(alpha);
            else
                % Sans consigne, on prend le plus petit rayon qui garde la
                % forme d'un seul tenant : c'est le reglage utile, et
                % c'est celui que MATLAB appelle « critical alpha ».
                shp.Alpha = criticalAlpha(shp, 'one-region');
            end
        end

        function T = alphaTriangulation(shp)
        %ALPHATRIANGULATION Triangles retenus par le rayon ALPHA.
            T = matlibre_triangles_alpha(shp.Points(:, 1), shp.Points(:, 2), shp.Alpha);
        end

        function a = area(shp)
        %AREA Aire de la forme, somme de celle de ses triangles.
            T = alphaTriangulation(shp);
            P = shp.Points;
            a = 0;
            for e = 1:size(T, 1)
                s = T(e, :);
                a = a + abs((P(s(2), 1) - P(s(1), 1)) * (P(s(3), 2) - P(s(1), 2)) - ...
                            (P(s(3), 1) - P(s(1), 1)) * (P(s(2), 2) - P(s(1), 2))) / 2;
            end
        end

        function F = boundaryFacets(shp)
        %BOUNDARYFACETS Arêtes du bord : celles qui n'ont qu'un triangle.
            T = alphaTriangulation(shp);
            if isempty(T)
                F = zeros(0, 2);
                return
            end
            aretes = [T(:, [1 2]); T(:, [2 3]); T(:, [3 1])];
            [~, ~, position] = unique(sort(aretes, 2), 'rows');
            compte = accumarray(position(:), 1);
            F = aretes(compte(position) == 1, :);
        end

        function p = perimeter(shp)
        %PERIMETER Longueur du bord.
            F = boundaryFacets(shp);
            P = shp.Points;
            p = 0;
            for e = 1:size(F, 1)
                p = p + norm(P(F(e, 2), :) - P(F(e, 1), :));
            end
        end

        function dedans = inShape(shp, xq, yq)
        %INSHAPE Points intérieurs à la forme.
        %   Un point est dedans s'il tombe dans l'un des triangles retenus.
            if nargin == 3
                Q = [double(xq(:)), double(yq(:))];
            else
                Q = double(xq);
            end
            T = alphaTriangulation(shp);
            P = shp.Points;
            dedans = false(size(Q, 1), 1);
            for k = 1:size(Q, 1)
                for e = 1:size(T, 1)
                    poids = matlibre_bary_poids(P(T(e, :), :), Q(k, :));
                    if all(poids >= -1e-12)
                        dedans(k) = true;
                        break
                    end
                end
            end
        end

        function n = numRegions(shp)
        %NUMREGIONS Nombre de morceaux séparés.
            T = alphaTriangulation(shp);
            n = matlibre_composantes_triangles(T);
        end

        function a = criticalAlpha(shp, critere)
        %CRITICALALPHA Plus petit rayon qui tient un critère.
        %   'one-region' : le plus petit rayon pour lequel la forme est
        %   d'un seul tenant. 'all-points' : le plus petit pour lequel tout
        %   point appartient encore à un triangle.
            if nargin < 2, critere = 'one-region'; end
            x = shp.Points(:, 1);
            y = shp.Points(:, 2);
            T = delaunay(x, y);
            if isempty(T)
                a = inf;
                return
            end
            rayons = zeros(size(T, 1), 1);
            for e = 1:size(T, 1)
                rayons(e) = matlibre_rayon_circonscrit([x(T(e, :)), y(T(e, :))]);
            end
            candidats = unique(sort(rayons));
            % Le critere est monotone en alpha — agrandir le rayon ne peut
            % que garder plus de triangles —, donc une recherche
            % dichotomique sur la liste des rayons suffit.
            bas = 1; haut = numel(candidats);
            a = candidats(end);
            while bas <= haut
                milieu = floor((bas + haut) / 2);
                essai = shp;
                essai.Alpha = candidats(milieu);
                if satisfait(essai, critere)
                    a = candidats(milieu);
                    haut = milieu - 1;
                else
                    bas = milieu + 1;
                end
            end
        end
    end
end

function ok = satisfait(shp, critere)
% Le critere est-il tenu pour ce rayon ?
    T = alphaTriangulation(shp);
    if isempty(T)
        ok = false;
        return
    end
    if strcmp(critere, 'all-points')
        ok = numel(unique(T(:))) == size(shp.Points, 1);
    else
        ok = matlibre_composantes_triangles(T) == 1 && ...
             numel(unique(T(:))) == size(shp.Points, 1);
    end
end
