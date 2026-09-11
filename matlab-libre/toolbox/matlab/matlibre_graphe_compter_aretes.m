function n = matlibre_graphe_compter_aretes(g, source, cible)
%MATLIBRE_GRAPHE_COMPTER_ARETES Nombre d'arêtes entre deux nœuds.
%   N = MATLIBRE_GRAPHE_COMPTER_ARETES(G,S,T) compte les arêtes joignant
%   S à T. Sur un graphe non orienté, le sens ne compte pas.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
%
%   Exemple :
%      matlibre_graphe_compter_aretes(graph([1 1], [2 2]), 1, 2)   % 2
%
%   Voir aussi EDGECOUNT, FINDEDGE, ISMULTIGRAPH.
    source = matlibre_graphe_indices(g, source);
    cible = matlibre_graphe_indices(g, cible);
    source = source(:)';
    cible = cible(:)';
    if numel(source) == 1 && numel(cible) > 1
        source = repmat(source, 1, numel(cible));
    elseif numel(cible) == 1 && numel(source) > 1
        cible = repmat(cible, 1, numel(source));
    end
    n = zeros(numel(source), 1);
    arcs = g.Arcs;
    for k = 1:numel(source)
        if isa(g, 'digraph')
            n(k) = sum(arcs(:, 1) == source(k) & arcs(:, 2) == cible(k));
        else
            n(k) = sum((arcs(:, 1) == source(k) & arcs(:, 2) == cible(k)) | ...
                       (arcs(:, 1) == cible(k) & arcs(:, 2) == source(k)));
        end
    end
end
