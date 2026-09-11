function h = matlibre_graphe_retourner(g, source, cible)
%MATLIBRE_GRAPHE_RETOURNER Retourne le sens de certains arcs.
%   H = MATLIBRE_GRAPHE_RETOURNER(G,S,T) rend le graphe où les arcs
%   allant de S à T ont été retournés ; les autres ne bougent pas.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
%
%   Exemple :
%      h = matlibre_graphe_retourner(digraph([1 2], [2 3]), 1, 2);
%      h.Arcs(1, :)                    % 2 1 : l'arc a change de sens
%
%   Voir aussi FLIPEDGE, DIGRAPH.
    source = matlibre_graphe_indices(g, source);
    cible = matlibre_graphe_indices(g, cible);
    source = source(:)';
    cible = cible(:)';
    if numel(source) == 1 && numel(cible) > 1
        source = repmat(source, 1, numel(cible));
    elseif numel(cible) == 1 && numel(source) > 1
        cible = repmat(cible, 1, numel(source));
    end
    arcs = g.Arcs;
    for k = 1:numel(source)
        aRetourner = arcs(:, 1) == source(k) & arcs(:, 2) == cible(k);
        arcs(aRetourner, :) = arcs(aRetourner, [2 1]);
    end
    h = matlibre_graphe_depuis(g, arcs, g.Poids, g.Noms, g.Nombre);
end
