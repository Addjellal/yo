function H = gname(etiquettes, poigneeTrace)
%GNAME Étiquette les points d'un nuage.
%   GNAME(ETIQUETTES) écrit à côté de chaque point du tracé courant le
%   nom correspondant du tableau de cellules ETIQUETTES.
%
%   GNAME sans argument numérote les points de 1 à N.
%
%   GNAME(ETIQUETTES,H) n'étiquette que les points de la courbe dont H
%   est la poignée.
%
%   H = GNAME(...) rend les poignées des textes posés.
%
%   Dans MATLAB, GNAME attend un clic de souris et n'étiquette que le
%   point désigné. MatLibre n'a pas de curseur interactif sur ses
%   figures : il étiquette tous les points d'un coup, ce qui rend le même
%   service quand le nuage est petit — et c'est bien pour un petit nuage
%   qu'on étiquette.
%
%   Exemples :
%      x = [1 2 3 4];
%      y = [2 4 3 5];
%      plot(x, y, 'o');
%      gname({'nord', 'sud', 'est', 'ouest'});
%
%   Voir aussi TEXT, PLOT, BOXPLOT, GSCATTER.
    if nargin < 2 || isempty(poigneeTrace)
        [x, y] = matlibre_points_traces();
    else
        x = get(poigneeTrace, 'XData');
        y = get(poigneeTrace, 'YData');
    end
    x = x(:);
    y = y(:);
    n = numel(x);
    if nargin < 1 || isempty(etiquettes)
        etiquettes = cell(n, 1);
        for i = 1:n
            etiquettes{i} = num2str(i);
        end
    end
    if ischar(etiquettes)
        etiquettes = cellstr(etiquettes);
    end
    etiquettes = etiquettes(:);
    aEffacer = ishold();
    hold('on');
    H = [];
    bornes = xlim();
    decalage = 0.01 * (bornes(2) - bornes(1));
    for i = 1:min(n, numel(etiquettes))
        H(end + 1) = text(x(i) + decalage, y(i), char(etiquettes{i}));   %#ok<AGROW>
    end
    if ~aEffacer
        hold('off');
    end
    if nargout == 0
        clear H;
    end
end
