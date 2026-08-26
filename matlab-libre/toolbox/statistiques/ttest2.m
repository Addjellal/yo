function [h, p, ci, stats] = ttest2(x, y, alpha)
%TTEST2 Test de Student sur deux échantillons indépendants.
    if nargin < 3
        alpha = 0.05;
    end
    x = x(:);
    y = y(:);
    nx = numel(x);
    ny = numel(y);
    sp2 = ((nx - 1) * var(x) + (ny - 1) * var(y)) / (nx + ny - 2);
    erreurType = sqrt(sp2 * (1/nx + 1/ny));
    t = (mean(x) - mean(y)) / erreurType;
    ddl = nx + ny - 2;
    p = 2 * (1 - tcdf(abs(t), ddl));
    h = double(p < alpha);
    marge = tinv(1 - alpha / 2, ddl) * erreurType;
    ci = [mean(x) - mean(y) - marge, mean(x) - mean(y) + marge];
    stats = struct('tstat', t, 'df', ddl, 'sd', sqrt(sp2));
end
