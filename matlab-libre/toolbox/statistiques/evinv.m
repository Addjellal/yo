function x = evinv(p, mu, sigma)
%EVINV Quantile de la loi des valeurs extrêmes.
    if nargin < 2, mu = 0; end
    if nargin < 3, sigma = 1; end
    [p, mu, sigma] = statAjuster(p, mu, sigma);
    x = mu + sigma .* log(-log(1 - p));
    x(p == 0) = -Inf;
    x(p == 1) = Inf;
    x(p < 0 | p > 1 | sigma <= 0) = NaN;
end
