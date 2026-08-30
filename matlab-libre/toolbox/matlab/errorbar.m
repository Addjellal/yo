function errorbar(varargin)
%ERRORBAR Courbe avec barres d'erreur.
%   ERRORBAR(Y,E) trace Y et, sur chaque point, une barre verticale allant
%   de Y-E à Y+E.
%
%   ERRORBAR(X,Y,E) place les points en X.
%
%   ERRORBAR(X,Y,BAS,HAUT) donne des écarts différents vers le bas et vers
%   le haut.
%
%   ERRORBAR(...,STYLE) prend une chaîne de style, comme PLOT.
%
%   Exemple :
%      x = 1:5;
%      y = [2 4 3 5 4];
%      errorbar(x, y, 0.4 * ones(size(y)), 'o-');
%
%   Voir aussi PLOT, BAR, STAIRS, STD.
    style = '';
    entrees = varargin;
    if ~isempty(entrees) && (ischar(entrees{end}) || isstring(entrees{end}))
        style = char(entrees{end});
        entrees = entrees(1:end-1);
    end
    switch numel(entrees)
        case 2
            y = entrees{1}(:); bas = entrees{2}(:); haut = bas;
            x = (1:numel(y))';
        case 3
            x = entrees{1}(:); y = entrees{2}(:); bas = entrees{3}(:); haut = bas;
        case 4
            x = entrees{1}(:); y = entrees{2}(:); bas = entrees{3}(:); haut = entrees{4}(:);
        otherwise
            error('MATLAB:narginchk:notEnoughInputs', 'Not enough input arguments.');
    end
    if isscalar(bas), bas = bas * ones(size(y)); end
    if isscalar(haut), haut = haut * ones(size(y)); end

    % Les barres et leurs chapeaux, en une seule polyligne coupée par des
    % NaN : c'est ainsi qu'on dessine des segments séparés sans boucler
    % sur autant de tracés.
    largeur = 0.01 * (max(x) - min(x) + eps);
    xb = []; yb = [];
    for k = 1:numel(x)
        xb = [xb; x(k); x(k); NaN; ...
              x(k)-largeur; x(k)+largeur; NaN; ...
              x(k)-largeur; x(k)+largeur; NaN];      %#ok<AGROW>
        yb = [yb; y(k)-bas(k); y(k)+haut(k); NaN; ...
              y(k)-bas(k); y(k)-bas(k); NaN; ...
              y(k)+haut(k); y(k)+haut(k); NaN];      %#ok<AGROW>
    end
    if isempty(style)
        plot(x, y, 'o-', xb, yb, 'k-');
    else
        plot(x, y, style, xb, yb, 'k-');
    end
end
