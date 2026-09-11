function [acyclique, ordre] = matlibre_graphe_acyclique(g)
%MATLIBRE_GRAPHE_ACYCLIQUE Le graphe orienté est-il sans circuit ?
%   [T,ORDRE] = MATLIBRE_GRAPHE_ACYCLIQUE(G) rend vrai si G n'a aucun
%   circuit, et l'ordre topologique qui le prouve. C'est l'algorithme de
%   Kahn, mais sans erreur : ne pas pouvoir trier est ici la réponse, non
%   un échec.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
%
%   Exemple :
%      matlibre_graphe_acyclique(digraph([1 2], [2 3]))    % 1
%      matlibre_graphe_acyclique(digraph([1 2], [2 1]))    % 0
%
%   Voir aussi ISDAG, TOPOSORT, HASCYCLES.
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
    acyclique = numel(ordre) == n;
    ordre = ordre(:)';
end
