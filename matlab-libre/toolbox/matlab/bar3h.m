function H = bar3h(varargin)
%BAR3H Diagramme en barres horizontales à trois dimensions.
%   BAR3H(Z) fait ce que fait BAR3, les barres couchées.
%
%   H = BAR3H(...) rend les poignées.
%
%   Dans MatLibre, les barres restent verticales comme celles de BAR3,
%   rangées et colonnes échangées ; MATLAB les couche le long des x.
%
%   Exemples :
%      bar3h(magic(4));
%
%   Voir aussi BAR3, BARH, BAR, HEATMAP.
    H = bar3(varargin{:});
    % On couche le diagramme : les abscisses deviennent les ordonnees.
    for k = 1:numel(H)
        x = get(H(k), 'XData');
        y = get(H(k), 'YData');
        set(H(k), 'XData', y, 'YData', x);
    end
    bornes = xlim();
    ylim(bornes);
    xlim('auto');
    yticks(get(gca(), 'XTick'));
    if nargout == 0
        clear H;
    end
end
