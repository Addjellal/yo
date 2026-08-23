function [m, v] = unidstat(n)
%UNIDSTAT Moyenne et variance de la loi uniforme discrète.
%   Exemple :  [m,v] = unidstat(6)   % 3.5 et 35/12, un dé
    n = double(n);
    m = (n + 1) / 2;
    v = (n .^ 2 - 1) / 12;
    m(n < 1 | n ~= round(n)) = NaN;
    v(n < 1 | n ~= round(n)) = NaN;
end
