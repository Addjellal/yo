function [h, groupes] = matlibre_graphe_condensation(g)
%MATLIBRE_GRAPHE_CONDENSATION Graphe des composantes fortement connexes.
%   [H,GROUPES] = MATLIBRE_GRAPHE_CONDENSATION(G) rend le graphe dont
%   chaque nœud est une composante fortement connexe de G, et GROUPES le
%   numéro de composante de chaque nœud de G.
%
%   La condensation est toujours sans circuit : s'il en restait un, les
%   composantes qu'il relie n'en feraient qu'une. C'est ce qui permet de
%   ramener une question d'accessibilité sur un graphe quelconque à la
%   même question sur un graphe sans circuit.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
%
%   Exemple :
%      numnodes(matlibre_graphe_condensation(digraph([1 2 3], [2 1 3])))   % 2
%
%   Voir aussi CONDENSATION, CONNCOMP, ISDAG.
    groupes = conncomp(g);
    nombre = max([groupes 0]);
    arcs = zeros(0, 2);
    for k = 1:size(g.Arcs, 1)
        a = groupes(g.Arcs(k, 1));
        b = groupes(g.Arcs(k, 2));
        if a ~= b
            arcs(end + 1, :) = [a b];   %#ok<AGROW>
        end
    end
    if ~isempty(arcs)
        arcs = unique(arcs, 'rows');
    end
    h = matlibre_graphe_depuis(g, arcs, ones(size(arcs, 1), 1), {}, nombre);
end
