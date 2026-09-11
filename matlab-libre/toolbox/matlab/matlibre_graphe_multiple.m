function t = matlibre_graphe_multiple(g)
%MATLIBRE_GRAPHE_MULTIPLE Deux nœuds sont-ils joints plusieurs fois ?
%   T = MATLIBRE_GRAPHE_MULTIPLE(G) rend vrai si une même paire de nœuds
%   porte plus d'une arête. Une boucle unique ne suffit pas : ce qui fait
%   un multigraphe est la répétition, non le retour sur soi.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
%
%   Exemple :
%      matlibre_graphe_multiple(graph([1 1], [2 2]))   % 1 : deux fois 1-2
%      matlibre_graphe_multiple(graph([1], [1]))       % 0 : une boucle
%
%   Voir aussi ISMULTIGRAPH, SIMPLIFY.
    arcs = g.Arcs;
    if size(arcs, 1) < 2
        t = false;
        return
    end
    if ~isa(g, 'digraph')
        % Sur un graphe non orienté, 1-2 et 2-1 sont la même arête.
        arcs = [min(arcs, [], 2), max(arcs, [], 2)];
    end
    t = size(unique(arcs, 'rows'), 1) < size(arcs, 1);
end
