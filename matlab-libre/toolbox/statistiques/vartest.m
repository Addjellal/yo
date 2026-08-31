function [h, p, ci, statistiques] = vartest(x, v, varargin)
%VARTEST Test du khi-deux sur une variance.
%   H = VARTEST(X,V) teste l'hypothèse « la variance de X vaut V ». La
%   statistique est
%
%      chi2 = (N-1) * var(X) / V
%
%   qui suit, sous l'hypothèse et pour des données normales, une loi du
%   khi-deux à N-1 degrés de liberté.
%
%   [H,P] = VARTEST(...) rend la probabilité critique.
%   [H,P,CI] = VARTEST(...) rend l'intervalle de confiance de la
%   variance ; il n'est pas centré sur l'estimation, la loi du khi-deux
%   n'étant pas symétrique.
%   [H,P,CI,STATS] = VARTEST(...) rend la statistique et ses degrés de
%   liberté.
%
%   VARTEST(...,'Alpha',A) change le seuil, 0.05 par défaut.
%   VARTEST(...,'Tail',T) choisit le côté : 'both', 'right', 'left'.
%
%   Le test est sensible à la non-normalité : un échantillon à queues
%   lourdes le fait conclure à tort bien plus souvent que le seuil ne le
%   laisse croire.
%
%   Exemples :
%      x = randn(100, 1) * 3;
%      [h, p, ci] = vartest(x, 9)     % la vraie variance est 9
%      vartest(x, 1)                  % rejette : elle vaut bien plus
%
%   Voir aussi VARTEST2, TTEST, VAR, CHI2CDF, CHI2INV.
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
            error('stats:vartest:BadOption', 'Unknown option ''%s''.', nom);
        end
        k = k + 2;
    end
    x = x(:);
    x = x(~isnan(x));
    n = numel(x);
    if n < 2
        error('stats:vartest:NotEnoughData', 'VARTEST needs at least two values.');
    end
    ddl = n - 1;
    variance = var(x);
    chi2 = ddl * variance / v;
    switch cote
        case 'both'
            queue = chi2cdf(chi2, ddl);
            p = 2 * min(queue, 1 - queue);
            ci = [ddl * variance / chi2inv(1 - alpha / 2, ddl), ...
                  ddl * variance / chi2inv(alpha / 2, ddl)];
        case 'right'
            p = 1 - chi2cdf(chi2, ddl);
            ci = [ddl * variance / chi2inv(1 - alpha, ddl), Inf];
        case 'left'
            p = chi2cdf(chi2, ddl);
            ci = [0, ddl * variance / chi2inv(alpha, ddl)];
        otherwise
            error('stats:vartest:BadTail', ...
                  'The tail must be ''both'', ''right'' or ''left''.');
    end
    p = min(1, p);
    h = double(p < alpha);
    statistiques = struct('chisqstat', chi2, 'df', ddl);
end
