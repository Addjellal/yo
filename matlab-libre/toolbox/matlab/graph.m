classdef graph
%GRAPH Graphe non orienté.
%   G = GRAPH(S,T) construit le graphe dont les arêtes relient les nœuds
%   S(k) et T(k). G = GRAPH(S,T,W) leur donne des poids.
%   G = GRAPH(A) prend une matrice d'adjacence carrée et symétrique ; les
%   valeurs non nulles deviennent les poids.
%   G = GRAPH(S,T,W,NOMS) nomme les nœuds ; S et T peuvent alors être des
%   noms au lieu de numéros.
%
%   Un graphe non orienté n'a pas de sens de parcours : l'arête entre 1 et
%   2 est la même que celle entre 2 et 1, et la matrice d'adjacence est
%   symétrique. C'est tout ce qui le sépare de DIGRAPH, mais cela change
%   les algorithmes — un cycle, une composante connexe, un arbre couvrant
%   ne veulent pas dire la même chose dans les deux cas.
%
%   Propriétés : Edges, une table des arêtes et de leurs poids ; Nodes,
%   une table des nœuds et de leurs noms.
%
%   Ce qu'on lui fait : NUMNODES, NUMEDGES, ADJACENCY, DEGREE, NEIGHBORS,
%   SHORTESTPATH, SHORTESTPATHTREE, DISTANCES, CONNCOMP, MINSPANTREE,
%   BFSEARCH, DFSEARCH, ADDEDGE, ADDNODE, RMEDGE, RMNODE, SUBGRAPH,
%   LAPLACIAN, INCIDENCE, PLOT.
%
%   Exemple :
%      g = graph([1 2 3], [2 3 4]);
%      numnodes(g)                     % 4
%      numedges(g)                     % 3
%      shortestpath(g, 1, 4)           % 1 2 3 4
%      degree(g)'                      % 1 2 2 1
%
%   Voir aussi DIGRAPH, SHORTESTPATH, CONNCOMP, MINSPANTREE, ADJACENCY.
    properties
        Arcs = zeros(0, 2)     % une ligne par arête : [source cible]
        Poids = zeros(0, 1)
        Noms = {}
        Nombre = 0
    end
    properties (Dependent)
        Edges
        Nodes
    end
    methods
        function obj = graph(varargin)
            [obj.Arcs, obj.Poids, obj.Noms, obj.Nombre] = ...
                matlibre_graphe_construire(varargin, false);
        end

        function t = get.Edges(obj)
            t = struct('EndNodes', obj.Arcs, 'Weight', obj.Poids);
        end

        function t = get.Nodes(obj)
            t = struct('Name', {obj.Noms(:)});
        end

        function n = numnodes(obj), n = obj.Nombre; end
        function n = numedges(obj), n = size(obj.Arcs, 1); end

        function A = adjacency(obj, genre)
        %ADJACENCY Matrice d'adjacence du graphe.
            if nargin < 2, genre = 'unweighted'; end
            A = zeros(obj.Nombre);
            for k = 1:size(obj.Arcs, 1)
                p = 1;
                if strcmpi(char(genre), 'weighted'), p = obj.Poids(k); end
                A(obj.Arcs(k, 1), obj.Arcs(k, 2)) = p;
                A(obj.Arcs(k, 2), obj.Arcs(k, 1)) = p;
            end
        end

        function d = degree(obj, noeuds)
        %DEGREE Nombre d'arêtes touchant chaque nœud.
            d = zeros(obj.Nombre, 1);
            for k = 1:size(obj.Arcs, 1)
                d(obj.Arcs(k, 1)) = d(obj.Arcs(k, 1)) + 1;
                d(obj.Arcs(k, 2)) = d(obj.Arcs(k, 2)) + 1;
                if obj.Arcs(k, 1) == obj.Arcs(k, 2)
                    % Une boucle compte double : elle touche le nœud par
                    % ses deux bouts.
                    d(obj.Arcs(k, 1)) = d(obj.Arcs(k, 1));
                end
            end
            if nargin >= 2
                d = d(matlibre_graphe_indices(obj, noeuds));
            end
        end

        function v = neighbors(obj, n)
        %NEIGHBORS Voisins d'un nœud.
            n = matlibre_graphe_indices(obj, n);
            v = [];
            for k = 1:size(obj.Arcs, 1)
                if obj.Arcs(k, 1) == n, v(end + 1) = obj.Arcs(k, 2); end   %#ok<AGROW>
                if obj.Arcs(k, 2) == n, v(end + 1) = obj.Arcs(k, 1); end   %#ok<AGROW>
            end
            v = unique(v(:));
        end

        function L = laplacian(obj)
        %LAPLACIAN Matrice laplacienne : degrés moins adjacence.
            L = diag(degree(obj)) - adjacency(obj);
        end

        function I = incidence(obj)
        %INCIDENCE Matrice d'incidence nœuds par arêtes.
            I = zeros(obj.Nombre, size(obj.Arcs, 1));
            for k = 1:size(obj.Arcs, 1)
                I(obj.Arcs(k, 1), k) = 1;
                I(obj.Arcs(k, 2), k) = 1;
            end
        end

        function [chemin, longueur] = shortestpath(obj, source, cible, varargin)
        %SHORTESTPATH Plus court chemin entre deux nœuds.
            [chemin, longueur] = matlibre_graphe_dijkstra(obj, source, cible, varargin);
        end

        function D = distances(obj, varargin)
        %DISTANCES Longueur du plus court chemin entre tous les couples.
            D = matlibre_graphe_distances(obj, varargin);
        end

        function [groupes, tailles] = conncomp(obj, varargin)
        %CONNCOMP Composantes connexes.
            [groupes, tailles] = matlibre_graphe_composantes(obj, varargin);
        end

        function [arbre, cout] = minspantree(obj)
        %MINSPANTREE Arbre couvrant de poids minimal, par l'algorithme de Prim.
            [arbre, cout] = matlibre_graphe_prim(obj);
        end

        function ordre = bfsearch(obj, depart)
        %BFSEARCH Parcours en largeur.
            ordre = matlibre_graphe_parcours(obj, depart, true);
        end

        function ordre = dfsearch(obj, depart)
        %DFSEARCH Parcours en profondeur.
            ordre = matlibre_graphe_parcours(obj, depart, false);
        end

        function obj = addedge(obj, s, t, w)
        %ADDEDGE Ajoute une arête.
            if nargin < 4, w = 1; end
            s = matlibre_graphe_indices(obj, s);
            t = matlibre_graphe_indices(obj, t);
            obj.Arcs = [obj.Arcs; s(:), t(:)];
            obj.Poids = [obj.Poids; w(:)];
            obj.Nombre = max([obj.Nombre; s(:); t(:)]);
        end

        function obj = addnode(obj, n)
        %ADDNODE Ajoute des nœuds isolés.
            if isnumeric(n)
                obj.Nombre = obj.Nombre + n;
            else
                n = cellstr(n);
                obj.Noms = [obj.Noms(:); n(:)];
                obj.Nombre = obj.Nombre + numel(n);
            end
        end

        function obj = rmedge(obj, s, t)
        %RMEDGE Retire une arête.
            s = matlibre_graphe_indices(obj, s);
            t = matlibre_graphe_indices(obj, t);
            garde = ~((obj.Arcs(:, 1) == s & obj.Arcs(:, 2) == t) | ...
                      (obj.Arcs(:, 1) == t & obj.Arcs(:, 2) == s));
            obj.Arcs = obj.Arcs(garde, :);
            obj.Poids = obj.Poids(garde);
        end

        function obj = rmnode(obj, n)
        %RMNODE Retire un nœud et les arêtes qui le touchent.
            obj = matlibre_graphe_retirer(obj, n);
        end

        function obj = subgraph(obj, noeuds)
        %SUBGRAPH Sous-graphe induit par un ensemble de nœuds.
            obj = matlibre_graphe_sous(obj, noeuds);
        end

        function t = hascycles(obj)
        %HASCYCLES Le graphe contient-il un cycle ?
            t = ~isempty(matlibre_graphe_cycles(obj, 1));
        end

        function [cycles, aretes] = allcycles(obj, varargin)
        %ALLCYCLES Tous les cycles simples.
            maximum = [];
            for k = 1:2:numel(varargin) - 1
                if strcmpi(char(varargin{k}), 'MaxNumCycles')
                    maximum = varargin{k + 1};
                end
            end
            [cycles, aretes] = matlibre_graphe_cycles(obj, maximum);
            cycles = cycles(:);
            aretes = aretes(:);
        end

        function [chemins, aretes] = allpaths(obj, source, cible, varargin)
        %ALLPATHS Tous les chemins simples d'un nœud à un autre.
            maximum = [];
            for k = 1:2:numel(varargin) - 1
                if strcmpi(char(varargin{k}), 'MaxNumPaths')
                    maximum = varargin{k + 1};
                end
            end
            [chemins, aretes] = matlibre_graphe_chemins(obj, source, cible, maximum);
            chemins = chemins(:);
            aretes = aretes(:);
        end

        function obj = reordernodes(obj, ordre)
        %REORDERNODES Renumérote les nœuds suivant un ordre donné.
            obj = matlibre_graphe_reordonner(obj, ordre);
        end

        function t = ismultigraph(obj)
        %ISMULTIGRAPH Deux nœuds sont-ils joints par plusieurs arêtes ?
            t = matlibre_graphe_multiple(obj);
        end

        function indices = outedges(obj, noeud)
        %OUTEDGES Rangs des arêtes partant d'un nœud.
            indices = matlibre_graphe_aretes_sortantes(obj, ...
                matlibre_graphe_indices(obj, noeud))';
        end

        function indices = inedges(obj, noeud)
        %INEDGES Rangs des arêtes arrivant sur un nœud.
            indices = matlibre_graphe_aretes_entrantes(obj, ...
                matlibre_graphe_indices(obj, noeud))';
        end

        function n = edgecount(obj, source, cible)
        %EDGECOUNT Nombre d'arêtes entre deux nœuds.
            n = matlibre_graphe_compter_aretes(obj, source, cible);
        end

        function [noeuds, d] = nearest(obj, source, rayon, varargin)
        %NEAREST Nœuds à portée d'un nœud donné.
            [noeuds, d] = matlibre_graphe_proches(obj, source, rayon, varargin{:});
        end

        function t = isisomorphic(obj, autre)
        %ISISOMORPHIC Les deux graphes se correspondent-ils ?
            t = matlibre_graphe_isomorphe(obj, autre);
        end

        function p = isomorphism(obj, autre)
        %ISOMORPHISM Permutation qui fait correspondre les deux graphes.
            [ok, p] = matlibre_graphe_isomorphe(obj, autre);
            if ~ok
                p = [];
            else
                p = p(:);
            end
        end

        function [cycles, aretes] = cyclebasis(obj)
        %CYCLEBASIS Base de cycles fondamentaux.
            [cycles, aretes] = matlibre_graphe_base_cycles(obj);
            cycles = cycles(:);
            aretes = aretes(:);
        end

        function h = plot(obj, varargin)
        %PLOT Trace le graphe, les nœuds sur un cercle.
            h = matlibre_graphe_tracer(obj, varargin);
        end

        function disp(obj)
            fprintf('  graph : %d noeuds, %d aretes\n', numnodes(obj), numedges(obj));
        end
    end
end
