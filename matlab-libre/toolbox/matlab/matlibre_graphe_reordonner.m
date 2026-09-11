function h = matlibre_graphe_reordonner(g, ordre)
%MATLIBRE_GRAPHE_REORDONNER Renumérote les nœuds d'un graphe.
%   H = MATLIBRE_GRAPHE_REORDONNER(G,ORDRE) rend le même graphe dont le
%   nœud k est celui qui portait le numéro ORDRE(k). ORDRE doit être une
%   permutation de 1 à N : renuméroter n'est pas trier, et il ne doit ni
%   manquer ni se répéter un nœud.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
%
%   Exemple :
%      h = matlibre_graphe_reordonner(graph([1 2], [2 3]), [3 2 1]);
%      h.Arcs                          % les aretes suivent les noeuds
%
%   Voir aussi REORDERNODES, SUBGRAPH.
    n = g.Nombre;
    ordre = matlibre_graphe_indices(g, ordre);
    ordre = ordre(:)';
    if numel(ordre) ~= n || ~isequal(sort(ordre), 1:n)
        error('MATLAB:graph:InvalidNodeOrder', ...
              'REORDERNODES attend une permutation des %d nœuds.', n);
    end
    nouveau = zeros(1, n);
    nouveau(ordre) = 1:n;
    arcs = g.Arcs;
    if ~isempty(arcs)
        arcs = nouveau(arcs);
        if size(arcs, 2) ~= 2
            arcs = reshape(arcs, [], 2);
        end
    end
    noms = g.Noms;
    if ~isempty(noms)
        noms = noms(ordre);
    end
    h = matlibre_graphe_depuis(g, arcs, g.Poids, noms, n);
end
