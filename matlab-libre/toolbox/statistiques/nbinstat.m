function [m, v] = nbinstat(r, p)
%NBINSTAT Moyenne et variance de la loi binomiale négative.
%   Exemple :  [m,v] = nbinstat(3, 0.5)   % 3 et 6
    [r, p] = statAjuster(r, p);
    m = r .* (1 - p) ./ p;
    v = r .* (1 - p) ./ p .^ 2;
    mauvais = r <= 0 | p <= 0 | p > 1;
    m(mauvais) = NaN;
    v(mauvais) = NaN;
end
