function b = matlibre_graphe_autre_bout(g, arete, courant)
%MATLIBRE_GRAPHE_AUTRE_BOUT Nœud atteint en empruntant une arête.
%   B = MATLIBRE_GRAPHE_AUTRE_BOUT(G,ARETE,COURANT) rend le nœud où l'on
%   arrive. Sur un graphe orienté c'est toujours la cible ; sur un graphe
%   non orienté, c'est l'autre extrémité que celle d'où l'on vient.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
%
%   Exemple :
%      matlibre_graphe_autre_bout(graph([1 2], [2 3]), 1, 2)   % 1
%
%   Voir aussi ALLPATHS, ALLCYCLES.
    couple = g.Arcs(arete, :);
    if isa(g, 'digraph')
        b = couple(2);
    elseif couple(1) == courant
        b = couple(2);
    else
        b = couple(1);
    end
end
