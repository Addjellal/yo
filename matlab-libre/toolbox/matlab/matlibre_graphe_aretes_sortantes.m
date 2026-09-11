function indices = matlibre_graphe_aretes_sortantes(g, noeud)
%MATLIBRE_GRAPHE_ARETES_SORTANTES Arêtes qu'on peut emprunter depuis un nœud.
%   INDICES = MATLIBRE_GRAPHE_ARETES_SORTANTES(G,N) rend les rangs des
%   arêtes partant de N. Sur un graphe non orienté, une arête se parcourt
%   dans les deux sens : toutes celles qui touchent N en font partie.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
%
%   Exemple :
%      matlibre_graphe_aretes_sortantes(graph([1 2], [2 3]), 2)   % [1 2]
%
%   Voir aussi OUTEDGES, INEDGES, ALLPATHS.
    if isa(g, 'digraph')
        indices = find(g.Arcs(:, 1) == noeud)';
    else
        indices = find(g.Arcs(:, 1) == noeud | g.Arcs(:, 2) == noeud)';
    end
end
