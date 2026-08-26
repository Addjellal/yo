function x = logninv(p, mu, sigma)
%LOGNINV Quantile de la loi log-normale.
%   Le logarithme d'une variable log-normale est normal : le quantile est
%   l'exponentielle de celui de la normale.
%
%   Exemple :  logninv(0.5, 0, 1)   % 1
    if nargin < 2, mu = 0; end
    if nargin < 3, sigma = 1; end
    [p, mu, sigma] = statAjuster(p, mu, sigma);
    x = exp(mu + sigma .* norminv(p));
    x(p == 0) = 0;
    x(sigma <= 0 | p < 0 | p > 1) = NaN;
end
