function [y, delta] = polyconf(p, x, S, varargin)
%POLYCONF Évalue un polynôme ajusté et l'incertitude de la prédiction.
%   Y = POLYCONF(P,X) évalue le polynôme P en X : c'est POLYVAL.
%
%   [Y,DELTA] = POLYCONF(P,X,S) rend en outre la demi-largeur de
%   l'intervalle de prédiction à 95 pour cent, à partir de la structure S
%   que rend POLYFIT. Y ± DELTA encadre une observation future en X avec
%   cette probabilité.
%
%   POLYCONF(...,'alpha',A) change le niveau.
%   POLYCONF(...,'predopt','curve') donne l'intervalle de la courbe
%   ajustée elle-même — celui de la moyenne de Y en X — au lieu de celui
%   d'une observation future. Il est plus étroit : il ne compte pas la
%   dispersion résiduelle, seulement l'incertitude sur les coefficients.
%   'observation' est le défaut.
%   POLYCONF(...,'simopt','on') élargit l'intervalle de façon qu'il
%   vaille simultanément pour tous les X, et non pour chacun pris à part.
%
%   Exemples :
%      x = (0:0.5:10)';
%      y = 2 * x + 1 + randn(size(x));
%      [p, S] = polyfit(x, y, 1);
%      [yy, delta] = polyconf(p, x, S);
%      plot(x, y, 'o', x, yy, '-', x, yy - delta, 'r:', x, yy + delta, 'r:');
%
%      [~, etroit] = polyconf(p, x, S, 'predopt', 'curve');
%      max(etroit) < max(delta)             % vrai : la courbe est mieux
%                                           % connue qu'une observation
%
%   Voir aussi POLYFIT, POLYVAL, NLPARCI, REGRESS, FITLM.
    alpha = 0.05;
    prediction = 'observation';
    simultane = false;
    k = 1;
    while k + 1 <= numel(varargin)
        nom = lower(char(varargin{k}));
        switch nom
            case 'alpha'
                alpha = varargin{k + 1};
            case 'predopt'
                prediction = lower(char(varargin{k + 1}));
            case 'simopt'
                simultane = strcmpi(char(varargin{k + 1}), 'on');
            case 'mu'
                % accepté et sans effet : MatLibre n'ajuste pas en
                % variable centrée réduite
            otherwise
                error('stats:polyconf:BadOption', 'Unknown option ''%s''.', nom);
        end
        k = k + 2;
    end
    y = polyval(p, x);
    if nargout < 2
        return;
    end
    if nargin < 3 || isempty(S)
        error('stats:polyconf:NoStructure', ...
              'The prediction interval needs the structure POLYFIT returns.');
    end
    ordre = numel(p) - 1;
    ddl = S.df;
    if ddl <= 0
        delta = Inf(size(y));
        return;
    end
    % La matrice de plan en X, et la covariance des coefficients : R
    % vient de la factorisation QR faite par POLYFIT. Les colonnes vont
    % du degré le plus haut au plus bas, comme les coefficients.
    xv = x(:);
    A = zeros(numel(xv), ordre + 1);
    for j = 0:ordre
        A(:, j + 1) = xv .^ (ordre - j);
    end
    E = A / S.R;
    variance = sum(E .^ 2, 2);
    sigma = S.normr / sqrt(ddl);
    if strcmp(prediction, 'curve')
        echelle = sqrt(variance);
    else
        echelle = sqrt(variance + 1);
    end
    if simultane
        % Bande de Scheffe : elle vaut pour tous les X a la fois.
        critique = sqrt((ordre + 1) * finv(1 - alpha, ordre + 1, ddl));
    else
        critique = tinv(1 - alpha / 2, ddl);
    end
    delta = reshape(critique * sigma * echelle, size(y));
end
