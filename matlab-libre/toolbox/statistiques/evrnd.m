function r = evrnd(mu, sigma, varargin)
%EVRND Tirages d'une loi des valeurs extrêmes.
%   R = EVRND(MU,SIGMA,M,N) rend une matrice M sur N de tirages.
%
%   Le tirage se fait par inversion : appliquer la fonction quantile à un
%   tirage uniforme. C'est exact, et cela ne demande aucun rejet.
%
%   Exemple :
%      r = evrnd(0, 1, 10000, 1);
%      abs(median(r) - evinv(0.5, 0, 1)) < 0.05    % true
%
%   Voir aussi EVINV, EVCDF, GEVRND.
    if nargin < 1, mu = 0; end
    if nargin < 2, sigma = 1; end
    forme = statForme(size(mu + sigma), varargin);
    mu = statEtendre(mu, forme);
    sigma = statEtendre(sigma, forme);
    r = mu + sigma .* log(-log(rand(forme)));
    r(sigma <= 0) = NaN;
end
