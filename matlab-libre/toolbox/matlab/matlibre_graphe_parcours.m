function ordre = matlibre_graphe_parcours(g, depart, enLargeur)
%MATLIBRE_GRAPHE_PARCOURS Parcours en largeur ou en profondeur.
%   Les deux ne diffèrent que par la structure d'attente : une file pour
%   la largeur, une pile pour la profondeur. C'est tout, et cela suffit à
%   changer complètement l'ordre de visite — la largeur trouve les plus
%   courts chemins en nombre d'arêtes, la profondeur descend d'abord.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
%
%   Exemple :
%      matlibre_graphe_parcours(graph([1 1], [2 3]), 1, true)     % 1 2 3
%
%   Voir aussi BFSEARCH, DFSEARCH, GRAPH, DIGRAPH.
    depart = matlibre_graphe_indices(g, depart);
    vu = false(g.Nombre, 1);
    attente = depart;
    vu(depart) = true;
    ordre = [];
    while ~isempty(attente)
        if enLargeur
            courant = attente(1);
            attente(1) = [];
        else
            courant = attente(end);
            attente(end) = [];
        end
        ordre(end + 1) = courant;   %#ok<AGROW>
        suivants = matlibre_graphe_voisins(g, courant, false);
        suivants = unique(suivants(:))';
        if ~enLargeur
            suivants = fliplr(suivants);
        end
        for v = suivants
            if ~vu(v)
                vu(v) = true;
                attente(end + 1) = v;   %#ok<AGROW>
            end
        end
    end
    ordre = ordre(:);
end
