classdef digraph
%DIGRAPH Graphe orienté.
%   G = DIGRAPH(S,T) construit le graphe dont les arcs vont de S(k) vers
%   T(k). G = DIGRAPH(S,T,W) leur donne des poids.
%   G = DIGRAPH(A) prend une matrice d'adjacence : A(i,j) non nul décrit
%   un arc de i vers j, et la matrice n'a pas à être symétrique.
%   G = DIGRAPH(S,T,W,NOMS) nomme les nœuds.
%
%   L'orientation change tout ce qui suit. Un chemin de 1 vers 4 n'est pas
%   un chemin de 4 vers 1 ; la connexité se décline en forte et faible ;
%   un tri topologique n'existe que s'il n'y a pas de cycle. C'est pour
%   cela que DIGRAPH et GRAPH sont deux classes et non une seule avec un
%   drapeau.
%
%   Propriétés : Edges, une table des arcs et de leurs poids ; Nodes, une
%   table des nœuds.
%
%   Ce qu'on lui fait : NUMNODES, NUMEDGES, ADJACENCY, INDEGREE, OUTDEGREE,
%   SUCCESSORS, PREDECESSORS, SHORTESTPATH, DISTANCES, CONNCOMP, TOPOSORT,
%   BFSEARCH, DFSEARCH, ADDEDGE, ADDNODE, RMEDGE, RMNODE, SUBGRAPH, PLOT.
%
%   Exemple :
%      g = digraph([1 2 3], [2 3 4]);
%      shortestpath(g, 1, 4)           % 1 2 3 4
%      isempty(shortestpath(g, 4, 1))  % 1 : on ne remonte pas un arc
%      toposort(g)                     % 1 2 3 4
%
%   Voir aussi GRAPH, SHORTESTPATH, TOPOSORT, CONNCOMP.
    properties
        Arcs = zeros(0, 2)
        Poids = zeros(0, 1)
        Noms = {}
        Nombre = 0
    end
    properties (Dependent)
        Edges
        Nodes
    end
    methods
        function obj = digraph(varargin)
            [obj.Arcs, obj.Poids, obj.Noms, obj.Nombre] = ...
                matlibre_graphe_construire(varargin, true);
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
        %ADJACENCY Matrice d'adjacence, non symétrique.
            if nargin < 2, genre = 'unweighted'; end
            A = zeros(obj.Nombre);
            for k = 1:size(obj.Arcs, 1)
                p = 1;
                if strcmpi(char(genre), 'weighted'), p = obj.Poids(k); end
                A(obj.Arcs(k, 1), obj.Arcs(k, 2)) = p;
            end
        end

        function d = indegree(obj, noeuds)
        %INDEGREE Nombre d'arcs entrants.
            d = zeros(obj.Nombre, 1);
            for k = 1:size(obj.Arcs, 1)
                d(obj.Arcs(k, 2)) = d(obj.Arcs(k, 2)) + 1;
            end
            if nargin >= 2, d = d(matlibre_graphe_indices(obj, noeuds)); end
        end

        function d = outdegree(obj, noeuds)
        %OUTDEGREE Nombre d'arcs sortants.
            d = zeros(obj.Nombre, 1);
            for k = 1:size(obj.Arcs, 1)
                d(obj.Arcs(k, 1)) = d(obj.Arcs(k, 1)) + 1;
            end
            if nargin >= 2, d = d(matlibre_graphe_indices(obj, noeuds)); end
        end

        function v = successors(obj, n)
        %SUCCESSORS Nœuds vers lesquels un arc part.
            n = matlibre_graphe_indices(obj, n);
            v = unique(obj.Arcs(obj.Arcs(:, 1) == n, 2));
        end

        function v = predecessors(obj, n)
        %PREDECESSORS Nœuds d'où un arc arrive.
            n = matlibre_graphe_indices(obj, n);
            v = unique(obj.Arcs(obj.Arcs(:, 2) == n, 1));
        end

        function [chemin, longueur] = shortestpath(obj, source, cible, varargin)
        %SHORTESTPATH Plus court chemin, dans le sens des arcs.
            [chemin, longueur] = matlibre_graphe_dijkstra(obj, source, cible, varargin);
        end

        function D = distances(obj, varargin)
        %DISTANCES Longueur du plus court chemin entre tous les couples.
            D = matlibre_graphe_distances(obj, varargin);
        end

        function [groupes, tailles] = conncomp(obj, varargin)
        %CONNCOMP Composantes connexes, fortes par défaut.
            [groupes, tailles] = matlibre_graphe_composantes(obj, varargin);
        end

        function ordre = toposort(obj)
        %TOPOSORT Tri topologique, par l'algorithme de Kahn.
            ordre = matlibre_graphe_toposort(obj);
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
        %ADDEDGE Ajoute un arc.
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
        %RMEDGE Retire un arc, dans le sens donné.
            s = matlibre_graphe_indices(obj, s);
            t = matlibre_graphe_indices(obj, t);
            garde = ~(obj.Arcs(:, 1) == s & obj.Arcs(:, 2) == t);
            obj.Arcs = obj.Arcs(garde, :);
            obj.Poids = obj.Poids(garde);
        end

        function obj = rmnode(obj, n)
        %RMNODE Retire un nœud et les arcs qui le touchent.
            obj = matlibre_graphe_retirer(obj, n);
        end

        function obj = subgraph(obj, noeuds)
        %SUBGRAPH Sous-graphe induit.
            obj = matlibre_graphe_sous(obj, noeuds);
        end

        function h = plot(obj, varargin)
        %PLOT Trace le graphe, les nœuds sur un cercle.
            h = matlibre_graphe_tracer(obj, varargin);
        end

        function disp(obj)
            fprintf('  digraph : %d noeuds, %d arcs\n', numnodes(obj), numedges(obj));
        end
    end
end
