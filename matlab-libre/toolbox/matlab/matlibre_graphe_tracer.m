function h = matlibre_graphe_tracer(g, options)
%MATLIBRE_GRAPHE_TRACER Dessine un graphe, les nœuds répartis sur un cercle.
%   La disposition circulaire n'est pas un choix esthétique : elle est
%   déterministe et sans paramètre, là où les dispositions par forces
%   dépendent d'un tirage et d'une convergence. Un même graphe se dessine
%   donc toujours pareil.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
%
%   Exemple :
%      figure();
%      matlibre_graphe_tracer(graph([1 2], [2 3]), {});
%      close all;
%
%   Voir aussi PLOT, GRAPH, DIGRAPH.
    n = g.Nombre;
    if n == 0
        h = [];
        return
    end
    angles = (0:n - 1)' * 2 * pi / n;
    x = cos(angles);
    y = sin(angles);
    tenu = ishold();
    hold on;
    for k = 1:size(g.Arcs, 1)
        a = g.Arcs(k, 1);
        b = g.Arcs(k, 2);
        plot([x(a) x(b)], [y(a) y(b)], 'k-');
    end
    h = plot(x, y, 'o');
    for k = 1:n
        if isempty(g.Noms)
            etiquette = sprintf('%d', k);
        else
            etiquette = g.Noms{k};
        end
        text(x(k) * 1.1, y(k) * 1.1, etiquette);
    end
    axis equal;
    if ~tenu
        hold off;
    end
    for k = 1:2:numel(options) - 1   %#ok<NASGU>
        % Les options de mise en forme sont acceptees et sans effet ici.
    end
end
