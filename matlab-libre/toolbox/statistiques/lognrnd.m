function r = lognrnd(mu, sigma, varargin)
%LOGNRND Tirages d'une loi log-normale.
    if nargin < 1, mu = 0; end
    if nargin < 2, sigma = 1; end
    forme = statForme(size(mu + sigma), varargin);
    mu = statEtendre(mu, forme);
    sigma = statEtendre(sigma, forme);
    r = exp(mu + sigma .* randn(forme));
    r(sigma <= 0) = NaN;
end
