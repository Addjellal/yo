function [m, v] = lognstat(mu, sigma)
%LOGNSTAT Moyenne et variance de la loi log-normale.
%   MU et SIGMA sont ceux du logarithme, pas ceux de la variable.
%
%   Exemple :  [m,v] = lognstat(0, 1)   % exp(0.5) et e(e-1)
    if nargin < 1, mu = 0; end
    if nargin < 2, sigma = 1; end
    [mu, sigma] = statAjuster(mu, sigma);
    m = exp(mu + sigma .^ 2 / 2);
    v = exp(2 * mu + sigma .^ 2) .* (exp(sigma .^ 2) - 1);
    m(sigma <= 0) = NaN;
    v(sigma <= 0) = NaN;
end
