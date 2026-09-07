function [suivants, couts] = matlibre_graphe_voisins(g, n, aRebours)
%MATLIBRE_GRAPHE_VOISINS Nœuds atteignables depuis N, et le coût pour y aller.
%   Sur un GRAPH, une arête se parcourt dans les deux sens ; sur un
%   DIGRAPH, seulement dans le sien. AREBOURS remonte les arcs, ce dont a
%   besoin la recherche de composantes fortement connexes.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
%
%   Exemple :
%      g = digraph([1 2], [2 3]);
%      matlibre_graphe_voisins(g, 1, false)'     % 2
%
%   Voir aussi GRAPH, DIGRAPH, SHORTESTPATH.
    if nargin < 3, aRebours = false; end
    oriente = isa(g, 'digraph');
    suivants = [];
    couts = [];
    for k = 1:size(g.Arcs, 1)
        a = g.Arcs(k, 1);
        b = g.Arcs(k, 2);
        if aRebours
            temporaire = a; a = b; b = temporaire;
        end
        if a == n
            suivants(end + 1) = b;          %#ok<AGROW>
            couts(end + 1) = g.Poids(k);    %#ok<AGROW>
        elseif ~oriente && b == n
            suivants(end + 1) = a;          %#ok<AGROW>
            couts(end + 1) = g.Poids(k);    %#ok<AGROW>
        end
    end
    suivants = suivants(:);
    couts = couts(:);
end
