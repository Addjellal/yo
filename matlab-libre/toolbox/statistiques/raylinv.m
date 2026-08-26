function x = raylinv(p, b)
%RAYLINV Quantile de la loi de Rayleigh de paramètre B.
%   Exemple :  raylinv(0.5, 1)   % sqrt(2 log 2) = 1.1774
    if nargin < 2, b = 1; end
    [p, b] = statAjuster(p, b);
    x = b .* sqrt(-2 * log(1 - p));
    x(p == 0) = 0;
    x(p < 0 | p > 1 | b <= 0) = NaN;
end
