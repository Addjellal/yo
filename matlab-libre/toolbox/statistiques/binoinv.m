function x = binoinv(y, n, pr)
%BINOINV Quantile de la loi binomiale.
%   Le plus petit entier X tel que BINOCDF(X,N,P) >= Y.
%
%   Exemple :  binoinv(0.5, 10, 0.5)   % 5
    [y, n, pr] = statAjuster(y, n, pr);
    x = zeros(size(y));
    for k = 1:numel(y)
        if ~(y(k) >= 0 && y(k) <= 1) || pr(k) < 0 || pr(k) > 1 || ...
                n(k) < 0 || n(k) ~= round(n(k))
            x(k) = NaN;
            continue
        end
        nn = n(k);
        pp = pr(k);
        depart = round(nn * pp);
        x(k) = statQuantileDiscret(@(t) binocdf(t, nn, pp), y(k), depart, nn);
    end
end
