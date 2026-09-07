function [chemin, longueur] = shortestpath(g, source, cible, varargin)
%SHORTESTPATH Plus court chemin entre deux nœuds d'un graphe.
%   CHEMIN = SHORTESTPATH(G,S,T) rend la suite des nœuds du plus court
%   chemin de S vers T, ou un tableau vide s'il n'y en a aucun.
%   [CHEMIN,LONGUEUR] = SHORTESTPATH(...) rend en outre sa longueur, somme
%   des poids traversés.
%   [...] = SHORTESTPATH(...,'Method','unweighted') ignore les poids et
%   compte les arêtes.
%
%   Sur un DIGRAPH, le chemin suit le sens des arcs : il peut exister de S
%   vers T et non de T vers S. Sur un GRAPH, les deux sens se valent.
%
%   L'algorithme est celui de Dijkstra, qui suppose des poids positifs.
%   Avec un poids négatif il rendrait un résultat faux sans le dire :
%   son raisonnement est qu'un nœud une fois atteint au moindre coût ne
%   peut plus être amélioré, ce qu'un arc négatif dément.
%
%   Exemple :
%      g = graph([1 2 1], [2 3 3], [1 1 5]);
%      [c, l] = shortestpath(g, 1, 3);
%      c                               % 1 2 3 : le detour est moins cher
%      l                               % 2
%      d = digraph([1 2 3], [2 3 4]);
%      isempty(shortestpath(d, 4, 1))  % 1 : on ne remonte pas un arc
%
%   Voir aussi GRAPH, DIGRAPH, DISTANCES, CONNCOMP, MINSPANTREE.
    [chemin, longueur] = matlibre_graphe_dijkstra(g, source, cible, varargin);
end
