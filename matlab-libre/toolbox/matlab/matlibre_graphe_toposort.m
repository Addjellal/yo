function ordre = matlibre_graphe_toposort(g)
%MATLIBRE_GRAPHE_TOPOSORT Tri topologique par l'algorithme de Kahn.
%   On retire à chaque pas un nœud sans prédécesseur. S'il n'en reste
%   aucun alors que des nœuds subsistent, c'est qu'il y a un cycle — et un
%   graphe cyclique n'admet aucun ordre topologique.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
%
%   Exemple :
%      matlibre_graphe_toposort(digraph([1 2], [2 3]))'     % 1 2 3
%
%   Voir aussi TOPOSORT, DIGRAPH, CONNCOMP.
    n = g.Nombre;
    entrant = zeros(n, 1);
    for k = 1:size(g.Arcs, 1)
        entrant(g.Arcs(k, 2)) = entrant(g.Arcs(k, 2)) + 1;
    end
    disponibles = find(entrant == 0)';
    ordre = [];
    restant = g.Arcs;
    while ~isempty(disponibles)
        courant = disponibles(1);
        disponibles(1) = [];
        ordre(end + 1) = courant;   %#ok<AGROW>
        garde = true(size(restant, 1), 1);
        for k = 1:size(restant, 1)
            if restant(k, 1) == courant
                garde(k) = false;
                cible = restant(k, 2);
                entrant(cible) = entrant(cible) - 1;
                if entrant(cible) == 0
                    disponibles(end + 1) = cible;   %#ok<AGROW>
                end
            end
        end
        restant = restant(garde, :);
    end
    if numel(ordre) < n
        error('MATLAB:digraph:CycleDetected', ...
              'Un graphe cyclique n''admet pas de tri topologique.');
    end
    ordre = ordre(:);
end
