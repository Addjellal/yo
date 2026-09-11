function [cycles, aretes] = matlibre_graphe_cycles(g, maximum)
%MATLIBRE_GRAPHE_CYCLES Tous les cycles simples d'un graphe.
%   [CYCLES,ARETES] = MATLIBRE_GRAPHE_CYCLES(G) rend, dans deux cellules,
%   les nœuds et les arêtes de chaque cycle ne repassant ni par un nœud
%   ni par une arête.
%
%   Chaque cycle est énuméré une fois. Deux précautions y suffisent : on
%   n'explore qu'à partir de son plus petit nœud, et sur un graphe non
%   orienté on ne garde qu'un des deux sens de parcours. Sans elles, un
%   triangle se compterait six fois.
%
%   MAXIMUM, s'il est donné, arrête l'énumération : le nombre de cycles
%   d'un graphe dense croît plus vite que toute fonction polynomiale de
%   sa taille.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
%
%   Exemple :
%      numel(matlibre_graphe_cycles(graph([1 2 3], [2 3 1])))   % 1
%
%   Voir aussi ALLCYCLES, HASCYCLES, CYCLEBASIS.
    if nargin < 2 || isempty(maximum)
        maximum = inf;
    end
    n = g.Nombre;
    oriente = isa(g, 'digraph');
    cycles = {};
    aretes = {};
    vus = false(1, n);
    depart = 1;
    for d = 1:n
        depart = d;
        explorer(d, d, []);
        if numel(cycles) >= maximum
            break
        end
    end

    function explorer(courant, chemin, suite)
        if numel(cycles) >= maximum
            return
        end
        disponibles = matlibre_graphe_aretes_sortantes(g, courant);
        for k = 1:numel(disponibles)
            arete = disponibles(k);
            if any(suite == arete)
                continue
            end
            suivant = matlibre_graphe_autre_bout(g, arete, courant);
            if suivant == depart
                if ~oriente && numel(chemin) >= 3 && chemin(2) > chemin(end)
                    continue
                end
                if ~oriente && numel(chemin) == 2 && ~isempty(suite) && suite(1) > arete
                    continue
                end
                cycles{end + 1} = chemin;             %#ok<AGROW>
                aretes{end + 1} = [suite arete];      %#ok<AGROW>
                if numel(cycles) >= maximum
                    return
                end
                continue
            end
            if suivant < depart || vus(suivant)
                continue
            end
            vus(suivant) = true;
            explorer(suivant, [chemin suivant], [suite arete]);
            vus(suivant) = false;
        end
    end
end
