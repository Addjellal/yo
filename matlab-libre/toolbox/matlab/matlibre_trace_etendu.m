function [x, y] = matlibre_trace_etendu(axe)
%MATLIBRE_TRACE_ETENDU Le tracé d'un axe qui couvre le plus de terrain.
%   [X,Y] = MATLIBRE_TRACE_ETENDU(AXE) rend les coordonnées du tracé dont
%   le cadre est le plus grand. Sans argument, il prend l'axe courant.
%
%   Cela sert à examiner un tracé sans dépendre de l'ordre dans lequel
%   FINDOBJ rend les objets, ni de ce que d'autres tracés — une pointe de
%   flèche, un repère — auraient ajouté à côté. Le nombre de points ne
%   suffirait pas : une pointe de flèche en a trois, une liaison droite
%   deux.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
%
%   Exemple :
%      figure; plot([0 10], [0 0]); hold on; plot([1 2], [0 1]);
%      max(matlibre_trace_etendu(gca))            % 10
%
%   Voir aussi FINDOBJ, GET, LINE.
    if nargin < 1
        axe = gca;
    end
    traces = findobj(axe, 'Type', 'line');
    x = [];
    y = [];
    meilleur = -1;
    for k = 1:numel(traces)
        cx = get(traces(k), 'XData');
        cy = get(traces(k), 'YData');
        if isempty(cx)
            continue
        end
        etendue = (max(cx) - min(cx)) + (max(cy) - min(cy));
        if etendue > meilleur
            meilleur = etendue;
            x = cx;
            y = cy;
        end
    end
end
