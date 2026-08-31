function nouvelles = copyobj(poignees, cible)
%COPYOBJ Recopie des objets graphiques dans un autre axe.
%   H = COPYOBJ(POIGNEES,AX) recopie dans l'axe AX les objets désignés
%   par POIGNEES, et rend les poignées des copies. C'est ainsi qu'on
%   reprend une courbe déjà tracée dans une autre figure sans en
%   recalculer les données.
%
%   MatLibre recopie les courbes et les textes, avec leurs données et
%   leur apparence.
%
%   Exemples :
%      figure(1); h = plot(1:10, (1:10).^2, 'r', 'LineWidth', 2);
%      figure(2); ax = gca;
%      copyobj(h, ax);
%
%   Voir aussi FINDOBJ, GET, SET, GCA, SUBPLOT.
    ancien = gca();
    nouvelles = [];
    for k = 1:numel(poignees)
        source = poignees(k);
        genre = get(source, 'Type');
        axes(cible);
        aEffacer = ishold();
        hold('on');
        if strcmp(genre, 'text')
            position = get(source, 'Position');
            copie = text(position(1), position(2), get(source, 'String'), ...
                         'FontSize', get(source, 'FontSize'), ...
                         'Color', get(source, 'Color'));
        else
            copie = plot(get(source, 'XData'), get(source, 'YData'), ...
                         'Color', get(source, 'Color'), ...
                         'LineWidth', get(source, 'LineWidth'), ...
                         'LineStyle', get(source, 'LineStyle'));
        end
        if ~aEffacer
            hold('off');
        end
        nouvelles = [nouvelles; copie];      %#ok<AGROW>
    end
    axes(ancien);
    if nargout == 0
        clear nouvelles;
    end
end
