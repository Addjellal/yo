function [noeuds, distances_] = matlibre_graphe_proches(g, source, rayon, varargin)
%MATLIBRE_GRAPHE_PROCHES Nœuds à portée d'un nœud donné.
%   [N,D] = MATLIBRE_GRAPHE_PROCHES(G,S,R) rend les nœuds dont la
%   distance à S ne dépasse pas R, classés par distance croissante, et
%   ces distances. Le nœud S lui-même n'y figure pas.
%
%   La distance est celle des poids d'arêtes, comme pour DISTANCES ;
%   R infini rend donc tous les nœuds accessibles.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
%
%   Exemple :
%      matlibre_graphe_proches(graph([1 2], [2 3]), 1, 1)   % 2
%
%   Voir aussi NEAREST, DISTANCES, SHORTESTPATH.
    source = matlibre_graphe_indices(g, source);
    toutes = distances(g, varargin{:});
    ligne = toutes(source, :);
    ligne(source) = inf;
    dedans = find(ligne <= rayon);
    [distances_, rang] = sort(ligne(dedans));
    noeuds = dedans(rang);
    noeuds = noeuds(:);
    distances_ = distances_(:);
end
