function c = geocdf(x, p)
%GEOCDF Répartition de la loi géométrique.
%   Exemple :  geocdf(2, 0.5)   % 0.875
    [x, p] = statAjuster(x, p);
    k = floor(x);
    c = zeros(size(x));
    dedans = k >= 0 & p > 0 & p <= 1;
    c(dedans) = 1 - (1 - p(dedans)) .^ (k(dedans) + 1);
    c(p < 0 | p > 1) = NaN;
end
