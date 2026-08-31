function H = refcurve(coefficients)
%REFCURVE Ajoute une courbe polynomiale de référence à un tracé.
%   REFCURVE(P) ajoute au tracé courant la courbe du polynôme dont les
%   coefficients sont P, rangés du degré le plus haut au plus bas comme
%   le veut POLYVAL. La courbe est dessinée d'un bout à l'autre de l'axe
%   des abscisses, sans en changer les limites.
%
%   REFCURVE sans argument ajoute la parabole des moindres carrés sur les
%   points déjà tracés.
%
%   H = REFCURVE(...) rend la poignée de la courbe.
%
%   Exemples :
%      x = linspace(-3, 3, 40);
%      plot(x, x .^ 2 + randn(1, 40) * 0.5, 'o');
%      refcurve([1 0 0]);          % la parabole vraie
%      refcurve;                   % celle des moindres carres
%
%   Voir aussi REFLINE, POLYFIT, POLYVAL, LINE.
    bornes = xlim();
    if nargin == 0
        [x, y] = matlibre_points_traces();
        if numel(x) < 3
            error('stats:refcurve:NoData', ...
                  'REFCURVE needs points on the axes, or coefficients.');
        end
        coefficients = polyfit(x, y, 2);
    end
    t = linspace(bornes(1), bornes(2), 200);
    aEffacer = ishold();
    hold('on');
    H = plot(t, polyval(coefficients, t), 'r--');
    if ~aEffacer
        hold('off');
    end
    xlim(bornes);
    if nargout == 0
        clear H;
    end
end
