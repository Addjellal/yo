function [h, p, ci, stats] = ttest(x, mu, alpha)
%TTEST Test de Student sur la moyenne d'un échantillon.
%   [H,P] = TTEST(X,MU) teste l'hypothèse « la moyenne de X vaut MU ».
%   H vaut 1 si l'hypothèse est rejetée au seuil ALPHA (5 % par défaut).
    if nargin < 2 || isempty(mu)
        mu = 0;
    end
    if nargin < 3
        alpha = 0.05;
    end
    x = x(:);
    n = numel(x);
    m = mean(x);
    s = std(x);
    erreurType = s / sqrt(n);
    t = (m - mu) / erreurType;
    ddl = n - 1;
    p = 2 * (1 - tcdf(abs(t), ddl));
    h = double(p < alpha);
    marge = tinv(1 - alpha / 2, ddl) * erreurType;
    ci = [m - marge, m + marge];
    stats = struct('tstat', t, 'df', ddl, 'sd', s);
end
