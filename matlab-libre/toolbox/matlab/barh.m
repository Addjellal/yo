function H = barh(varargin)
%BARH Diagramme en barres horizontales.
%   BARH(Y) trace une barre horizontale par élément de Y, la première en
%   bas. BARH(X,Y) place les barres aux ordonnées X.
%
%   BARH(...,LARGEUR) donne aux barres une largeur relative, 0.8 par
%   défaut. Une largeur de 1 les fait se toucher.
%
%   BARH(...,STYLE) accepte une chaîne de style comme PLOT, dont seule la
%   couleur est employée.
%
%   H = BARH(...) rend les poignées des barres.
%
%   Une barre horizontale se lit mieux qu'une verticale quand les
%   étiquettes sont longues : c'est le seul motif de préférer BARH à BAR.
%
%   Exemples :
%      barh([3 5 2 7]);
%      yticklabels({'nord', 'sud', 'est', 'ouest'});
%
%      barh([10 20 30], 0.5);
%
%   Voir aussi BAR, BAR3, PARETO, STAIRS, FILL, YTICKLABELS.
    [x, y, largeur, style] = matlibre_arguments_barres(varargin, 'barh');
    aEffacer = ishold();
    if ~aEffacer
        cla;
    end
    hold('on');
    H = [];
    demi = largeur / 2;
    for k = 1:numel(y)
        gauche = min(0, y(k));
        droite = max(0, y(k));
        H(end + 1) = fill([gauche, droite, droite, gauche], ...
                          [x(k) - demi, x(k) - demi, x(k) + demi, x(k) + demi], ...
                          style);    %#ok<AGROW>
    end
    if ~aEffacer
        hold('off');
    end
    ylim([min(x) - largeur, max(x) + largeur]);
    if nargout == 0
        clear H;
    end
end
