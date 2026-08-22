function [b, bint, r, rint, stats] = regress(y, X)
%REGRESS Régression linéaire multiple par moindres carrés.
%   B = REGRESS(Y,X) rend les coefficients de Y = X*B.
%   [B,BINT,R,RINT,STATS] = REGRESS(...) rend aussi les intervalles de
%   confiance à 95 %, les résidus, et [R2, F, p, variance résiduelle].
    y = y(:);
    b = X \ y;
    r = y - X * b;
    n = numel(y);
    p = size(X, 2);
    ddl = n - p;
    sigma2 = sum(r .^ 2) / max(ddl, 1);
    covariance = sigma2 * inv(X' * X);
    ecart = sqrt(diag(covariance));
    t = tinv(0.975, max(ddl, 1));
    bint = [b - t * ecart, b + t * ecart];
    rint = [r - t * sqrt(sigma2), r + t * sqrt(sigma2)];
    sct = sum((y - mean(y)) .^ 2);
    scr = sum(r .^ 2);
    R2 = 1 - scr / sct;
    F = (R2 / max(p - 1, 1)) / ((1 - R2) / max(ddl, 1));
    stats = [R2, F, 1 - fcdf(F, max(p-1,1), max(ddl,1)), sigma2];
end
