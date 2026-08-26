function [m, v] = wblstat(a, b)
%WBLSTAT Moyenne et variance de la loi de Weibull.
%   Les moments s'écrivent avec la fonction gamma :
%   E[X] = a*gamma(1+1/b), Var[X] = a^2*(gamma(1+2/b) - gamma(1+1/b)^2).
%
%   Exemple :  [m,v] = wblstat(1, 1)   % 1 et 1, la loi exponentielle
    if nargin < 1, a = 1; end
    if nargin < 2, b = 1; end
    [a, b] = statAjuster(a, b);
    g1 = gamma(1 + 1 ./ b);
    g2 = gamma(1 + 2 ./ b);
    m = a .* g1;
    v = a .^ 2 .* (g2 - g1 .^ 2);
    mauvais = a <= 0 | b <= 0;
    m(mauvais) = NaN;
    v(mauvais) = NaN;
end
