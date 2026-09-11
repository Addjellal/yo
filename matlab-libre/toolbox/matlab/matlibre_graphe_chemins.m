function [chemins, aretes] = matlibre_graphe_chemins(g, source, cible, maximum)
%MATLIBRE_GRAPHE_CHEMINS Tous les chemins simples d'un nœud à un autre.
%   [CHEMINS,ARETES] = MATLIBRE_GRAPHE_CHEMINS(G,S,T) rend, dans deux
%   cellules, la suite des nœuds et la suite des arêtes de chaque chemin
%   ne repassant jamais par le même nœud.
%
%   L'énumération se fait en profondeur, en marquant les nœuds du chemin
%   courant : c'est ce marquage, et lui seul, qui distingue un chemin
%   simple d'une promenade sans fin dans un cycle.
%
%   Le nombre de chemins peut croître très vite ; MAXIMUM, s'il est
%   donné, arrête l'énumération là.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
%
%   Exemple :
%      c = matlibre_graphe_chemins(digraph([1 1 2], [2 3 3]), 1, 3);
%      numel(c)                        % 2 : direct, et par le noeud 2
%
%   Voir aussi ALLPATHS, ALLCYCLES, SHORTESTPATH.
    if nargin < 4 || isempty(maximum)
        maximum = inf;
    end
    source = matlibre_graphe_indices(g, source);
    cible = matlibre_graphe_indices(g, cible);
    chemins = {};
    aretes = {};
    vus = false(1, g.Nombre);
    explorer(source, [source], []);

    function explorer(courant, chemin, suite)
        if numel(chemins) >= maximum
            return
        end
        if courant == cible && numel(chemin) > 0
            if numel(chemin) > 1 || source == cible
                chemins{end + 1} = chemin;   %#ok<AGROW>
                aretes{end + 1} = suite;     %#ok<AGROW>
                return
            end
        end
        vus(courant) = true;
        voisines = matlibre_graphe_aretes_sortantes(g, courant);
        for k = 1:numel(voisines)
            arete = voisines(k);
            suivant = matlibre_graphe_autre_bout(g, arete, courant);
            if vus(suivant)
                continue
            end
            explorer(suivant, [chemin suivant], [suite arete]);
        end
        vus(courant) = false;
    end
end
