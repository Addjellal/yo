function h = matlibre_graphe_depuis(modele, arcs, poids, noms, nombre)
%MATLIBRE_GRAPHE_DEPUIS Construit un graphe du même genre qu'un autre.
%   H = MATLIBRE_GRAPHE_DEPUIS(MODELE,ARCS,POIDS,NOMS,NOMBRE) rend un
%   GRAPH ou un DIGRAPH selon MODELE, portant les arêtes données.
%
%   Passer par les propriétés plutôt que par le constructeur permet de
%   garder les nœuds isolés : deux listes d'extrémités ne disent pas
%   combien de nœuds le graphe compte, et un nœud sans arête y
%   disparaîtrait.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
%
%   Exemple :
%      h = matlibre_graphe_depuis(graph(), [1 2], 1, {}, 3);
%      numnodes(h)                     % 3 : le troisieme noeud reste
%
%   Voir aussi GRAPH, DIGRAPH, REORDERNODES.
    if isa(modele, 'digraph')
        h = digraph();
    else
        h = graph();
    end
    if isempty(arcs)
        arcs = zeros(0, 2);
    end
    h.Arcs = arcs;
    h.Poids = poids(:);
    h.Noms = noms;
    h.Nombre = nombre;
end
