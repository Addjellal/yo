function [m, v] = gamstat(a, b)
%GAMSTAT Moyenne et variance de la loi gamma.
%   Exemple :  [m,v] = gamstat(2, 3)   % 6 et 18
    if nargin < 2, b = 1; end
    [a, b] = statAjuster(a, b);
    m = a .* b;
    v = a .* b .^ 2;
    mauvais = a <= 0 | b <= 0;
    m(mauvais) = NaN;
    v(mauvais) = NaN;
end
