function [m, v] = binostat(n, pr)
%BINOSTAT Moyenne et variance de la loi binomiale.
%   Exemple :  [m,v] = binostat(10, 0.5)   % 5 et 2.5
    [n, pr] = statAjuster(n, pr);
    m = n .* pr;
    v = n .* pr .* (1 - pr);
    mauvais = pr < 0 | pr > 1 | n < 0;
    m(mauvais) = NaN;
    v(mauvais) = NaN;
end
