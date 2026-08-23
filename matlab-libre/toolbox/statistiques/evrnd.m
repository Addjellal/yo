function r = evrnd(mu, sigma, varargin)
%EVRND Tirages d'une loi des valeurs extrêmes.
    if nargin < 1, mu = 0; end
    if nargin < 2, sigma = 1; end
    forme = statForme(size(mu + sigma), varargin);
    mu = statEtendre(mu, forme);
    sigma = statEtendre(sigma, forme);
    r = mu + sigma .* log(-log(rand(forme)));
    r(sigma <= 0) = NaN;
end
