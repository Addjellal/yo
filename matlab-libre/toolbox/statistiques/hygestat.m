function [moy, v] = hygestat(m, k, n)
%HYGESTAT Moyenne et variance de la loi hypergéométrique.
%   La variance porte le facteur de population finie (M-N)/(M-1).
%
%   Exemple :  [m,v] = hygestat(10, 4, 3)   % 1.2 et 0.56
    [m, k, n] = statAjuster(m, k, n);
    moy = n .* k ./ m;
    v = n .* (k ./ m) .* ((m - k) ./ m) .* ((m - n) ./ (m - 1));
    mauvais = m <= 0 | k < 0 | n < 0 | k > m | n > m;
    moy(mauvais) = NaN;
    v(mauvais) = NaN;
end
