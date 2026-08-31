function [h, p, ci, statistiques] = vartest2(x, y, varargin)
%VARTEST2 Test de Fisher sur l'égalité de deux variances.
%   H = VARTEST2(X,Y) teste l'hypothèse « X et Y ont la même variance ».
%   La statistique est le rapport des variances estimées, qui suit une
%   loi de Fisher-Snedecor sous l'hypothèse et pour des données normales.
%
%   [H,P] = VARTEST2(...) rend la probabilité critique.
%   [H,P,CI] = VARTEST2(...) rend l'intervalle de confiance du rapport
%   des variances.
%   [H,P,CI,STATS] = VARTEST2(...) rend la statistique et les deux degrés
%   de liberté.
%
%   VARTEST2(...,'Alpha',A) change le seuil ; VARTEST2(...,'Tail',T)
%   choisit le côté : 'both', 'right', 'left'.
%
%   C'est le test qu'on fait avant TTEST2 pour décider s'il faut ou non
%   demander l'option d'égalité des variances. Il est lui-même très
%   sensible à la non-normalité : sur des données douteuses, mieux vaut
%   employer directement la forme de TTEST2 qui ne suppose pas l'égalité.
%
%   Exemples :
%      x = randn(50, 1);
%      y = randn(50, 1) * 3;
%      [h, p] = vartest2(x, y)        % rejette : les variances different
%      vartest2(randn(50,1), randn(50,1))   % ne rejette pas
%
%   Voir aussi VARTEST, TTEST2, VAR, FCDF, FINV.
    alpha = 0.05;
    cote = 'both';
    k = 1;
    while k + 1 <= numel(varargin)
        nom = lower(char(varargin{k}));
        if strcmp(nom, 'alpha')
            alpha = varargin{k + 1};
        elseif strcmp(nom, 'tail')
            cote = lower(char(varargin{k + 1}));
        elseif strcmp(nom, 'dim')
            % accepté et sans effet
        else
            error('stats:vartest2:BadOption', 'Unknown option ''%s''.', nom);
        end
        k = k + 2;
    end
    x = x(:);
    y = y(:);
    x = x(~isnan(x));
    y = y(~isnan(y));
    nx = numel(x);
    ny = numel(y);
    if nx < 2 || ny < 2
        error('stats:vartest2:NotEnoughData', ...
              'VARTEST2 needs at least two values in each sample.');
    end
    ddlX = nx - 1;
    ddlY = ny - 1;
    rapport = var(x) / var(y);
    switch cote
        case 'both'
            queue = fcdf(rapport, ddlX, ddlY);
            p = 2 * min(queue, 1 - queue);
            ci = [rapport / finv(1 - alpha / 2, ddlX, ddlY), ...
                  rapport / finv(alpha / 2, ddlX, ddlY)];
        case 'right'
            p = 1 - fcdf(rapport, ddlX, ddlY);
            ci = [rapport / finv(1 - alpha, ddlX, ddlY), Inf];
        case 'left'
            p = fcdf(rapport, ddlX, ddlY);
            ci = [0, rapport / finv(alpha, ddlX, ddlY)];
        otherwise
            error('stats:vartest2:BadTail', ...
                  'The tail must be ''both'', ''right'' or ''left''.');
    end
    p = min(1, p);
    h = double(p < alpha);
    statistiques = struct('fstat', rapport, 'df1', ddlX, 'df2', ddlY);
end
