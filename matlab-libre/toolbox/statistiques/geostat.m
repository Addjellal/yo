function [m, v] = geostat(p)
%GEOSTAT Moyenne et variance de la loi géométrique.
%   Exemple :  [m,v] = geostat(0.25)   % 3 et 12
    p = double(p);
    m = (1 - p) ./ p;
    v = (1 - p) ./ p .^ 2;
    mauvais = p <= 0 | p > 1;
    m(mauvais) = NaN;
    v(mauvais) = NaN;
end
