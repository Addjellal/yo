function y = geopdf(x, p)
%GEOPDF Probabilité de la loi géométrique.
%   Comme dans MATLAB, X compte les échecs avant le premier succès : le
%   support est 0, 1, 2, ...
%
%   Exemple :  geopdf(2, 0.5)   % 0.125
    [x, p] = statAjuster(x, p);
    y = zeros(size(x));
    dedans = x >= 0 & x == round(x) & p > 0 & p <= 1;
    y(dedans) = p(dedans) .* (1 - p(dedans)) .^ x(dedans);
    y(p < 0 | p > 1) = NaN;
end
