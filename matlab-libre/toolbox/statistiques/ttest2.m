function [h, p, ci, stats] = ttest2(x, y, alpha)
%TTEST2 Test de Student sur deux échantillons indépendants.
%   [H,P] = TTEST2(X,Y) teste l'égalité des moyennes de deux échantillons
%   indépendants. H vaut un quand l'hypothèse d'égalité est rejetée au
%   seuil de cinq pour cent.
%
%   Le test suppose les deux échantillons normaux et de même variance. La
%   normalité importe peu au-delà de quelques dizaines d'observations —
%   le théorème central limite s'en charge —, mais l'égalité des variances
%   compte, et c'est le test de Welch qu'il faut quand elle n'est pas
%   tenue.
%
%   Ne pas rejeter n'est pas prouver l'égalité : c'est ne pas avoir assez
%   de données pour conclure. Un P grand se lit ainsi, et pas autrement.
%
%   Exemple :
%      [h, p] = ttest2(randn(50,1), randn(50,1) + 2);
%      h                               % 1 : les moyennes different
%      [h, p] = ttest2(randn(50,1), randn(50,1));
%      h                               % 0 le plus souvent
%
%   Voir aussi TTEST, ANOVA1, TCDF.
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
