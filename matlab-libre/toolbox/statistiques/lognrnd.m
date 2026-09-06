function r = lognrnd(mu, sigma, varargin)
%LOGNRND Tirages d'une loi log-normale.
%   R = LOGNRND(MU,SIGMA,M,N) rend exp(MU + SIGMA * randn), donc des
%   valeurs strictement positives.
%
%   MU et SIGMA sont ceux du logarithme : la médiane du tirage vaut
%   exp(MU), non MU, et sa moyenne exp(MU + SIGMA^2/2).
%
%   Exemple :
%      r = lognrnd(0, 1, 10000, 1);
%      abs(median(r) - 1) < 0.05       % true : exp(0)
%      all(r > 0)                      % true : toujours positif
%
%   Voir aussi LOGNCDF, LOGNINV, NORMRND.
    if nargin < 1, mu = 0; end
    if nargin < 2, sigma = 1; end
    forme = statForme(size(mu + sigma), varargin);
    mu = statEtendre(mu, forme);
    sigma = statEtendre(sigma, forme);
    r = exp(mu + sigma .* randn(forme));
    r(sigma <= 0) = NaN;
end
