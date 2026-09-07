function g = matlibre_graphe_retirer(g, noeuds)
%MATLIBRE_GRAPHE_RETIRER Retire des nœuds et renumérote les autres.
%   Retirer un nœud décale tous ceux qui le suivent : c'est la partie
%   délicate, et la seule raison pour laquelle cette fonction existe.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
%
%   Exemple :
%      numnodes(matlibre_graphe_retirer(graph([1 2], [2 3]), 3))   % 2
%
%   Voir aussi RMNODE, SUBGRAPH.
    aRetirer = matlibre_graphe_indices(g, noeuds);
    garde = setdiff(1:g.Nombre, aRetirer);
    g = matlibre_graphe_sous(g, garde);
end
