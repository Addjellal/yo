function x = wblinv(p, a, b)
%WBLINV Quantile de la loi de Weibull d'échelle A et de forme B.
%   Exemple :  wblinv(1 - exp(-1), 1, 1)   % 1
    if nargin < 2, a = 1; end
    if nargin < 3, b = 1; end
    [p, a, b] = statAjuster(p, a, b);
    x = a .* (-log(1 - p)) .^ (1 ./ b);
    x(p == 0) = 0;
    x(p == 1) = Inf;
    x(p < 0 | p > 1 | a <= 0 | b <= 0) = NaN;
end
