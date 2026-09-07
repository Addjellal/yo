function indices = matlibre_graphe_indices(g, noeuds)
%MATLIBRE_GRAPHE_INDICES Traduit des noms de nœuds en numéros.
%   Un nœud se désigne par son rang ou par son nom ; toutes les méthodes
%   des graphes acceptent les deux, et c'est ici que la traduction se fait.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
%
%   Exemple :
%      g = graph([1 2], [2 3]);
%      matlibre_graphe_indices(g, 2)      % 2
%
%   Voir aussi GRAPH, DIGRAPH.
    if isnumeric(noeuds) || islogical(noeuds)
        indices = double(noeuds(:));
        return
    end
    liste = cellstr(noeuds);
    indices = zeros(numel(liste), 1);
    for k = 1:numel(liste)
        j = find(strcmp(g.Noms, liste{k}), 1);
        if isempty(j)
            error('MATLAB:graph:UnknownNode', 'Nœud inconnu : %s.', liste{k});
        end
        indices(k) = j;
    end
end
