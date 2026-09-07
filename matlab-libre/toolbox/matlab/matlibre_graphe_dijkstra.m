function [chemin, longueur] = matlibre_graphe_dijkstra(g, source, cible, options)
%MATLIBRE_GRAPHE_DIJKSTRA Plus court chemin par l'algorithme de Dijkstra.
%   L'algorithme retient à chaque pas le nœud non visité le plus proche de
%   la source et le déclare définitif. Ce raisonnement n'est valable que
%   pour des poids positifs : un poids négatif pourrait rendre plus court,
%   plus tard, un chemin déjà tenu pour optimal.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
%
%   Exemple :
%      g = graph([1 2], [2 3]);
%      matlibre_graphe_dijkstra(g, 1, 3, {})     % 1 2 3
%
%   Voir aussi SHORTESTPATH, DISTANCES, GRAPH, DIGRAPH.
    if nargin < 4, options = {}; end
    nonPondere = false;
    for k = 1:2:numel(options) - 1
        if strcmpi(char(options{k}), 'method')
            nonPondere = strcmpi(char(options{k + 1}), 'unweighted');
        end
    end
    source = matlibre_graphe_indices(g, source);
    cible = matlibre_graphe_indices(g, cible);
    n = g.Nombre;
    distance = inf(n, 1);
    precedent = zeros(n, 1);
    vu = false(n, 1);
    distance(source) = 0;
    for pas = 1:n   %#ok<NASGU>
        candidats = distance;
        candidats(vu) = inf;
        [meilleure, courant] = min(candidats);
        if ~isfinite(meilleure), break, end
        vu(courant) = true;
        if courant == cible, break, end
        [suivants, couts] = matlibre_graphe_voisins(g, courant, false);
        if nonPondere, couts = ones(size(couts)); end
        for j = 1:numel(suivants)
            v = suivants(j);
            if distance(courant) + couts(j) < distance(v) - 1e-15
                distance(v) = distance(courant) + couts(j);
                precedent(v) = courant;
            end
        end
    end
    longueur = distance(cible);
    if ~isfinite(longueur)
        chemin = [];
        return
    end
    chemin = cible;
    while chemin(1) ~= source
        chemin = [precedent(chemin(1)); chemin];   %#ok<AGROW>
        if chemin(1) == 0
            chemin = [];
            longueur = Inf;
            return
        end
    end
    chemin = chemin(:)';
end
