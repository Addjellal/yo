function p = evcdf(x, mu, sigma)
%EVCDF Répartition de la loi des valeurs extrêmes.
%   Exemple :  evcdf(0, 0, 1)   % 1 - exp(-1) = 0.6321
    if nargin < 2, mu = 0; end
    if nargin < 3, sigma = 1; end
    [x, mu, sigma] = statAjuster(x, mu, sigma);
    p = 1 - exp(-exp((x - mu) ./ sigma));
    p(sigma <= 0) = NaN;
end
