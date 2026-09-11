function h = matlibre_graphe_fermeture(g)
%MATLIBRE_GRAPHE_FERMETURE Fermeture transitive d'un graphe orienté.
%   H = MATLIBRE_GRAPHE_FERMETURE(G) rend le graphe où un arc joint U à V
%   dès que V est accessible depuis U par un chemin quelconque. Les
%   boucles sur un nœud ne sont pas conservées.
%
%   L'accessibilité se calcule par un parcours depuis chaque nœud : c'est
%   en O(N*(N+E)), là où l'élévation répétée de la matrice d'adjacence
%   serait en O(N^3) sans être plus claire.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
%
%   Exemple :
%      numedges(matlibre_graphe_fermeture(digraph([1 2], [2 3])))   % 3
%
%   Voir aussi TRANSCLOSURE, TRANSREDUCTION, CONDENSATION.
    n = g.Nombre;
    arcs = zeros(0, 2);
    for depart = 1:n
        atteints = accessibles(g, depart, n);
        atteints(depart) = false;
        cibles = find(atteints);
        for k = 1:numel(cibles)
            arcs(end + 1, :) = [depart cibles(k)];   %#ok<AGROW>
        end
    end
    h = matlibre_graphe_depuis(g, arcs, ones(size(arcs, 1), 1), g.Noms, n);
end

function vus = accessibles(g, depart, n)
    vus = false(1, n);
    pile = depart;
    while ~isempty(pile)
        courant = pile(end);
        pile(end) = [];
        for arete = matlibre_graphe_aretes_sortantes(g, courant)
            suivant = matlibre_graphe_autre_bout(g, arete, courant);
            if ~vus(suivant)
                vus(suivant) = true;
                pile(end + 1) = suivant;   %#ok<AGROW>
            end
        end
    end
end
