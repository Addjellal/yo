function g = matlibre_graphe_sous(g, noeuds)
%MATLIBRE_GRAPHE_SOUS Sous-graphe induit par un ensemble de nœuds.
%   Ne sont gardées que les arêtes dont les deux extrémités survivent, et
%   les nœuds restants sont renumérotés dans l'ordre où ils sont donnés.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
%
%   Exemple :
%      numedges(matlibre_graphe_sous(graph([1 2], [2 3]), [1 2]))   % 1
%
%   Voir aussi SUBGRAPH, RMNODE.
    garde = matlibre_graphe_indices(g, noeuds);
    nouveau = zeros(g.Nombre, 1);
    nouveau(garde) = 1:numel(garde);
    survit = ismember(g.Arcs(:, 1), garde) & ismember(g.Arcs(:, 2), garde);
    arcs = g.Arcs(survit, :);
    poids = g.Poids(survit);
    if ~isempty(arcs)
        arcs = [nouveau(arcs(:, 1)), nouveau(arcs(:, 2))];
    end
    noms = {};
    if ~isempty(g.Noms)
        noms = g.Noms(garde);
    end
    if isa(g, 'digraph')
        g = digraph(arcs(:, 1), arcs(:, 2), poids);
    else
        g = graph(arcs(:, 1), arcs(:, 2), poids);
    end
    g.Nombre = numel(garde);
    g.Noms = noms;
end
