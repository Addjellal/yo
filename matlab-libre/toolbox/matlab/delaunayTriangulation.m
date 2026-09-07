classdef delaunayTriangulation < triangulation
%DELAUNAYTRIANGULATION Triangulation de Delaunay, avec ses requêtes.
%   DT = DELAUNAYTRIANGULATION(P) triangule les points P, une ligne par
%   point. DT = DELAUNAYTRIANGULATION(X,Y) accepte les coordonnées
%   séparées.
%
%   C'est la triangulation dont aucun cercle circonscrit ne contient de
%   point — la propriété du cercle vide. Elle maximise le plus petit
%   angle, ce qui évite les triangles étirés, et c'est pour cela qu'elle
%   sert de base à l'interpolation et au maillage.
%
%   La classe dérive de TRIANGULATION : EDGES, FREEBOUNDARY, NEIGHBORS,
%   CIRCUMCENTER, INCENTER et les autres s'appliquent telles quelles. Elle
%   y ajoute ce qu'on ne peut demander qu'à une triangulation de Delaunay :
%   CONVEXHULL rend l'enveloppe convexe, POINTLOCATION dit dans quel
%   triangle tombe un point, NEARESTNEIGHBOR quel sommet en est le plus
%   proche.
%
%   Le bord libre d'une triangulation de Delaunay est l'enveloppe convexe
%   des points : c'est une conséquence directe de la propriété du cercle
%   vide, et les tests s'en servent pour la vérifier.
%
%   Exemple :
%      P = [0 0; 1 0; 1 1; 0 1; 0.5 0.5];
%      dt = delaunayTriangulation(P);
%      size(dt.ConnectivityList, 1)    % quatre triangles
%      isa(dt, 'triangulation')        % 1 : elle en derive
%      pointLocation(dt, [0.6 0.4])    % le triangle qui contient ce point
%
%   Voir aussi TRIANGULATION, DELAUNAY, CONVHULL, VORONOI.
    properties
        Constraints = []
    end

    methods
        function dt = delaunayTriangulation(P, y)
            if nargin == 0
                return
            end
            if nargin == 2
                P = [double(P(:)), double(y(:))];
            end
            P = double(P);
            if size(P, 2) ~= 2
                error('MATLAB:delaunayTriangulation:Dimension', ...
                      'DELAUNAYTRIANGULATION ne traite que le plan.');
            end
            T = delaunay(P(:, 1), P(:, 2));
            dt@triangulation(T, P);
        end

        function k = convexHull(dt)
        %CONVEXHULL Enveloppe convexe des points, premier sommet répété.
            k = convhull(dt.Points(:, 1), dt.Points(:, 2));
        end

        function [indices, B] = pointLocation(dt, xq, yq)
        %POINTLOCATION Triangle contenant chaque point interrogé.
        %   NaN pour un point hors de la triangulation. [I,B] rend aussi
        %   les coordonnées barycentriques, dont les trois composantes
        %   sont positives précisément quand le point est dedans.
            if nargin == 3
                Q = [double(xq(:)), double(yq(:))];
            else
                Q = double(xq);
            end
            T = dt.ConnectivityList;
            P = dt.Points;
            indices = nan(size(Q, 1), 1);
            B = nan(size(Q, 1), 3);
            for k = 1:size(Q, 1)
                for e = 1:size(T, 1)
                    poids = matlibre_bary_poids(P(T(e, :), :), Q(k, :));
                    if all(poids >= -1e-12)
                        indices(k) = e;
                        B(k, :) = poids;
                        break
                    end
                end
            end
        end

        function indices = nearestNeighbor(dt, xq, yq)
        %NEARESTNEIGHBOR Sommet le plus proche de chaque point interrogé.
            if nargin == 3
                Q = [double(xq(:)), double(yq(:))];
            else
                Q = double(xq);
            end
            indices = zeros(size(Q, 1), 1);
            for k = 1:size(Q, 1)
                ecarts = sum((dt.Points - Q(k, :)) .^ 2, 2);
                [~, indices(k)] = min(ecarts);
            end
        end
    end
end
