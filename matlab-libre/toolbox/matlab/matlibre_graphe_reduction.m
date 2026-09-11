function h = matlibre_graphe_reduction(g)
%MATLIBRE_GRAPHE_REDUCTION Réduction transitive d'un graphe sans circuit.
%   H = MATLIBRE_GRAPHE_REDUCTION(G) retire les arcs qu'un chemin plus
%   long rend inutiles : U->V disparaît s'il existe un autre chemin de U
%   à V. H a la même accessibilité que G, avec le moins d'arcs possible.
%
%   Sur un graphe sans circuit, cette réduction est unique. Elle ne l'est
%   plus dès qu'il y a un circuit — n'importe lequel de ses arcs peut
%   être celui qu'on garde — et MatLibre refuse alors, plutôt que de
%   choisir en silence.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
%
%   Exemple :
%      numedges(matlibre_graphe_reduction(digraph([1 1 2], [2 3 3])))   % 2
%
%   Voir aussi TRANSREDUCTION, TRANSCLOSURE, ISDAG.
    if ~matlibre_graphe_acyclique(g)
        error('MATLAB:digraph:CycleDetected', ...
              ['La réduction transitive n''est unique que sur un graphe sans ' ...
               'circuit ; celui-ci en a un.']);
    end
    n = g.Nombre;
    arcs = unique(g.Arcs, 'rows');
    arcs = arcs(arcs(:, 1) ~= arcs(:, 2), :);
    garde = true(size(arcs, 1), 1);
    for k = 1:size(arcs, 1)
        depart = arcs(k, 1);
        cible = arcs(k, 2);
        % Un arc est superflu si la cible reste accessible sans lui.
        autres = arcs(garde, :);
        autres(all(autres == arcs(k, :), 2), :) = [];
        if accessibleSans(autres, depart, cible, n)
            garde(k) = false;
        end
    end
    arcs = arcs(garde, :);
    h = matlibre_graphe_depuis(g, arcs, ones(size(arcs, 1), 1), g.Noms, n);
end

function ok = accessibleSans(arcs, depart, cible, n)
    vus = false(1, n);
    pile = depart;
    ok = false;
    while ~isempty(pile)
        courant = pile(end);
        pile(end) = [];
        suivants = arcs(arcs(:, 1) == courant, 2)';
        for suivant = suivants
            if suivant == cible
                ok = true;
                return
            end
            if ~vus(suivant)
                vus(suivant) = true;
                pile(end + 1) = suivant;   %#ok<AGROW>
            end
        end
    end
end
