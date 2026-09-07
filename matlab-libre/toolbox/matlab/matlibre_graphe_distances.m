function D = matlibre_graphe_distances(g, options)
%MATLIBRE_GRAPHE_DISTANCES Longueur du plus court chemin entre tous les couples.
%   Un Dijkstra par source. Sur un graphe dense, Floyd-Warshall serait
%   préférable ; sur un graphe creux, c'est l'inverse — et un graphe est
%   presque toujours creux.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
%
%   Exemple :
%      D = matlibre_graphe_distances(graph([1 2], [2 3]), {});
%      D(1, 3)                         % 2
%
%   Voir aussi DISTANCES, SHORTESTPATH.
    if nargin < 2, options = {}; end
    n = g.Nombre;
    D = inf(n);
    for s = 1:n
        for t = 1:n
            if s == t
                D(s, t) = 0;
            else
                [~, D(s, t)] = matlibre_graphe_dijkstra(g, s, t, options);
            end
        end
    end
end
