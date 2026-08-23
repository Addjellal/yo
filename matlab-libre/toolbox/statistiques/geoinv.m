function x = geoinv(y, p)
%GEOINV Quantile de la loi géométrique.
    [y, p] = statAjuster(y, p);
    x = zeros(size(y));
    dedans = y > 0 & y < 1 & p > 0 & p < 1;
    x(dedans) = max(0, ceil(log(1 - y(dedans)) ./ log(1 - p(dedans)) - 1));
    x(y == 1) = Inf;
    x(p == 1) = 0;
    x(y < 0 | y > 1 | p <= 0 | p > 1) = NaN;
end
