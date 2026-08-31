function [x, y] = matlibre_points_traces()
%MATLIBRE_POINTS_TRACES Tous les points de l'axe courant, en vrac.
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
%   REFLINE, REFCURVE et LSLINE s'en servent pour ajuster une courbe sur
%   ce qui est déjà dessiné, sans qu'on ait à leur repasser les données.
    a = gca();
    donnees = get(a, 'Children');
    x = [];
    y = [];
    if isempty(donnees)
        return;
    end
    for k = 1:numel(donnees)
        xk = get(donnees(k), 'XData');
        yk = get(donnees(k), 'YData');
        x = [x, xk(:)'];      %#ok<AGROW>
        y = [y, yk(:)'];      %#ok<AGROW>
    end
end
