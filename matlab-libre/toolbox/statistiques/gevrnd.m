function r = gevrnd(k, sigma, mu, varargin)
%GEVRND Tirages d'une loi généralisée des valeurs extrêmes.
%   R = GEVRND(K,SIGMA,MU) tire une observation de la loi GEV.
%   R = GEVRND(K,SIGMA,MU,M,N) rend une matrice M x N de tirages.
%   R = GEVRND(K,SIGMA,MU,[M N]) fait la même chose.
%
%   Le tirage se fait par inversion : GEVINV appliqué à un tirage
%   uniforme, ce qui est exact et n'a pas de taux de rejet.
%
%   Exemples :
%      r = gevrnd(0.2, 1, 0, 1000, 1);
%      histfit(r, 30, 'kernel');
%      gevrnd(0, 1, 0, 3, 3)
%
%   Voir aussi GEVCDF, GEVPDF, GEVINV, EVRND, WBLRND.
    if nargin < 1 || isempty(k)
        k = 0;
    end
    if nargin < 2 || isempty(sigma)
        sigma = 1;
    end
    if nargin < 3 || isempty(mu)
        mu = 0;
    end
    forme = statForme(size(k + sigma + mu), varargin);
    u = rand(forme);
    r = gevinv(u, statEtendre(k, forme), statEtendre(sigma, forme), ...
               statEtendre(mu, forme));
end
