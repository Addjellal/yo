function x = nbininv(y, r, p)
%NBININV Quantile de la loi binomiale négative.
    [y, r, p] = statAjuster(y, r, p);
    x = zeros(size(y));
    for k = 1:numel(y)
        if ~(y(k) >= 0 && y(k) <= 1) || r(k) <= 0 || p(k) <= 0 || p(k) > 1
            x(k) = NaN;
            continue
        end
        if y(k) == 1 && p(k) < 1, x(k) = Inf; continue, end
        rr = r(k); pp = p(k);
        depart = round(rr * (1 - pp) / pp);
        x(k) = statQuantileDiscret(@(t) nbincdf(t, rr, pp), y(k), depart, 1e9);
    end
end
