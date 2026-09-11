function indices = matlibre_graphe_aretes_entrantes(g, noeud)
%MATLIBRE_GRAPHE_ARETES_ENTRANTES Arêtes qui aboutissent à un nœud.
%   INDICES = MATLIBRE_GRAPHE_ARETES_ENTRANTES(G,N) rend les rangs des
%   arêtes arrivant sur N. Sur un graphe non orienté, une arête n'a pas
%   de sens : ce sont les mêmes que les sortantes.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
%
%   Exemple :
%      matlibre_graphe_aretes_entrantes(digraph([1 2], [3 3]), 3)   % [1 2]
%
%   Voir aussi INEDGES, OUTEDGES.
    if isa(g, 'digraph')
        indices = find(g.Arcs(:, 2) == noeud)';
    else
        indices = matlibre_graphe_aretes_sortantes(g, noeud);
    end
end
