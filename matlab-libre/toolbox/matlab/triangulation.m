classdef triangulation
%TRIANGULATION Maillage de triangles ou de tétraèdres.
%   TR = TRIANGULATION(T,P) réunit une liste de connectivité T — une
%   ligne par élément, portant les indices de ses sommets — et les points
%   P, une ligne par point. C'est la façon dont MATLAB range un maillage :
%   les coordonnées d'un côté, la topologie de l'autre, ce qui permet de
%   déplacer les points sans refaire la connectivité.
%
%   TR = TRIANGULATION(T,X,Y) et TRIANGULATION(T,X,Y,Z) acceptent les
%   coordonnées séparées.
%
%   Ce qu'on lui demande : FREEBOUNDARY, EDGES, NEIGHBORS, CIRCUMCENTER,
%   INCENTER, FACENORMAL, VERTEXATTACHMENTS, EDGEATTACHMENTS, SIZE,
%   ISCONNECTED, BARYCENTRICTOCARTESIAN, CARTESIANTOBARYCENTRIC.
%
%   Exemple :
%      P = [0 0; 1 0; 1 1; 0 1];
%      T = [1 2 3; 1 3 4];
%      tr = triangulation(T, P);
%      size(freeBoundary(tr), 1)       % 4 : le carre a quatre cotes
%      size(edges(tr), 1)              % 5 : quatre cotes et la diagonale
%
%   Voir aussi DELAUNAYTRIANGULATION, DELAUNAY, FREEBOUNDARY, CONVHULL.
    properties
        ConnectivityList = zeros(0, 3)
        Points = zeros(0, 2)
    end

    methods
        function tr = triangulation(T, varargin)
            if nargin == 0
                return
            end
            if numel(varargin) == 1
                P = double(varargin{1});
            elseif numel(varargin) >= 2
                P = double(varargin{1}(:));
                for k = 2:numel(varargin)
                    P = [P, double(varargin{k}(:))];   %#ok<AGROW>
                end
            else
                error('MATLAB:triangulation:Arguments', ...
                      'TRIANGULATION attend une connectivité et des points.');
            end
            T = double(T);
            if isempty(T) || size(T, 2) < 3
                error('MATLAB:triangulation:Connectivite', ...
                      'La connectivité doit avoir au moins trois colonnes.');
            end
            if any(T(:) < 1) || any(T(:) > size(P, 1)) || any(T(:) ~= round(T(:)))
                error('MATLAB:triangulation:Indices', ...
                      'La connectivité doit indexer les points.');
            end
            tr.ConnectivityList = T;
            tr.Points = P;
        end

        function varargout = size(tr, dimension)
        %SIZE Taille de la liste de connectivité.
            if nargin > 1
                varargout{1} = size(tr.ConnectivityList, dimension);
                return
            end
            if nargout <= 1
                varargout{1} = size(tr.ConnectivityList);
            else
                s = size(tr.ConnectivityList);
                for k = 1:nargout
                    if k <= numel(s), varargout{k} = s(k); else, varargout{k} = 1; end
                end
            end
        end

        function e = edges(tr)
        %EDGES Arêtes distinctes du maillage.
        %   Chaque arête est rendue une fois, sommets en ordre croissant,
        %   et l'ensemble est trié.
            e = unique(sort(matlibre_tri_aretes(tr.ConnectivityList), 2), 'rows');
        end

        function [F, P] = freeBoundary(tr)
        %FREEBOUNDARY Bord libre : les faces qui n'appartiennent qu'à un élément.
        %   [F,P] = FREEBOUNDARY(TR) rend aussi les points employés, F
        %   étant alors renuméroté sur eux.
        %
        %   Une face intérieure est partagée par deux éléments ; une face
        %   du bord n'en a qu'un. C'est toute la définition, et c'est ce
        %   qui fait du bord libre le contour du maillage.
            toutes = matlibre_tri_aretes(tr.ConnectivityList);
            triees = sort(toutes, 2);
            [uniques, ~, position] = unique(triees, 'rows');
            compte = accumarray(position(:), 1, [size(uniques, 1) 1]);
            garde = find(compte == 1);
            F = zeros(numel(garde), size(uniques, 2));
            for k = 1:numel(garde)
                premiere = find(position == garde(k), 1);
                F(k, :) = toutes(premiere, :);
            end
            if nargout > 1
                noms = unique(F(:));
                renumerotation = zeros(size(tr.Points, 1), 1);
                renumerotation(noms) = 1:numel(noms);
                F = renumerotation(F);
                if size(F, 2) == 1, F = F'; end
                P = tr.Points(noms, :);
            end
        end

        function N = neighbors(tr)
        %NEIGHBORS Voisins de chaque élément, par face partagée.
        %   NaN là où la face n'a pas de voisin. La colonne J porte le
        %   voisin opposé au sommet J, comme dans MATLAB.
            T = tr.ConnectivityList;
            [nElements, nSommets] = size(T);
            N = nan(nElements, nSommets);
            faces = matlibre_tri_aretes(T);
            triees = sort(faces, 2);
            [~, ~, position] = unique(triees, 'rows');
            position = reshape(position, nElements, nSommets);
            for k = 1:max(position(:))
                [lignes, colonnes] = find(position == k);
                if numel(lignes) == 2
                    N(lignes(1), colonnes(1)) = lignes(2);
                    N(lignes(2), colonnes(2)) = lignes(1);
                end
            end
        end

        function C = circumcenter(tr, elements)
        %CIRCUMCENTER Centre du cercle circonscrit de chaque triangle.
        %   C'est le point équidistant des trois sommets : l'intersection
        %   des médiatrices.
            if nargin < 2, elements = (1:size(tr.ConnectivityList, 1))'; end
            C = matlibre_tri_centres(tr, elements, 'circonscrit');
        end

        function C = incenter(tr, elements)
        %INCENTER Centre du cercle inscrit de chaque triangle.
        %   C'est le barycentre des sommets pondérés par les longueurs des
        %   côtés opposés, donc le point équidistant des trois côtés.
            if nargin < 2, elements = (1:size(tr.ConnectivityList, 1))'; end
            C = matlibre_tri_centres(tr, elements, 'inscrit');
        end

        function A = vertexAttachments(tr, sommets)
        %VERTEXATTACHMENTS Éléments attachés à chaque sommet.
            if nargin < 2, sommets = (1:size(tr.Points, 1))'; end
            sommets = sommets(:);
            A = cell(numel(sommets), 1);
            for k = 1:numel(sommets)
                A{k} = find(any(tr.ConnectivityList == sommets(k), 2))';
            end
        end

        function A = edgeAttachments(tr, a, b)
        %EDGEATTACHMENTS Éléments qui portent chaque arête.
            if nargin == 2
                paires = double(a);
            else
                paires = [double(a(:)), double(b(:))];
            end
            A = cell(size(paires, 1), 1);
            T = tr.ConnectivityList;
            for k = 1:size(paires, 1)
                A{k} = find(any(T == paires(k, 1), 2) & any(T == paires(k, 2), 2))';
            end
        end

        function lie = isConnected(tr, a, b)
        %ISCONNECTED Vrai si les deux sommets partagent une arête.
            if nargin == 2
                paires = double(a);
            else
                paires = [double(a(:)), double(b(:))];
            end
            attaches = edgeAttachments(tr, paires);
            lie = false(size(paires, 1), 1);
            for k = 1:numel(attaches)
                lie(k) = ~isempty(attaches{k});
            end
        end

        function N = faceNormal(tr, elements)
        %FACENORMAL Normale unitaire de chaque triangle, en trois dimensions.
            if size(tr.Points, 2) ~= 3
                error('MATLAB:triangulation:Dimension', ...
                      'FACENORMAL demande des points en trois dimensions.');
            end
            if nargin < 2, elements = (1:size(tr.ConnectivityList, 1))'; end
            elements = elements(:);
            N = zeros(numel(elements), 3);
            for k = 1:numel(elements)
                s = tr.ConnectivityList(elements(k), 1:3);
                u = tr.Points(s(2), :) - tr.Points(s(1), :);
                v = tr.Points(s(3), :) - tr.Points(s(1), :);
                n = cross(u, v);
                N(k, :) = n / max(norm(n), eps);
            end
        end

        function X = barycentricToCartesian(tr, elements, B)
        %BARYCENTRICTOCARTESIAN Des coordonnées barycentriques aux cartésiennes.
            elements = elements(:);
            B = double(B);
            X = zeros(numel(elements), size(tr.Points, 2));
            for k = 1:numel(elements)
                s = tr.ConnectivityList(elements(k), :);
                X(k, :) = B(k, :) * tr.Points(s, :);
            end
        end

        function B = cartesianToBarycentric(tr, elements, X)
        %CARTESIANTOBARYCENTRIC Des coordonnées cartésiennes aux barycentriques.
        %   Les poids somment à un : c'est ce qui définit un barycentre.
            elements = elements(:);
            X = double(X);
            nSommets = size(tr.ConnectivityList, 2);
            B = zeros(numel(elements), nSommets);
            for k = 1:numel(elements)
                s = tr.ConnectivityList(elements(k), :);
                sommets = tr.Points(s, :);
                M = [sommets'; ones(1, nSommets)];
                B(k, :) = (M \ [X(k, :)'; 1])';
            end
        end
    end
end
