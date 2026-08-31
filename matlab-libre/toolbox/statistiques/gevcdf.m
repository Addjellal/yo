function p = gevcdf(x, k, sigma, mu)
%GEVCDF Répartition de la loi généralisée des valeurs extrêmes.
%   P = GEVCDF(X,K,SIGMA,MU) rend la répartition de la loi GEV de
%   paramètre de forme K, d'échelle SIGMA et de position MU :
%
%      F(x) = exp( -(1 + k*(x-mu)/sigma)^(-1/k) )       si k ~= 0
%      F(x) = exp( -exp(-(x-mu)/sigma) )                si k = 0
%
%   Le signe de K décide de la famille : K > 0 donne la loi de Fréchet,
%   à queue lourde ; K < 0 la loi de Weibull renversée, bornée à droite ;
%   K = 0 la loi de Gumbel, celle des valeurs extrêmes ordinaire.
%
%   Le support est borné d'un côté dès que K n'est pas nul : la
%   répartition vaut 0 ou 1 au-delà.
%
%   Les arguments par défaut sont K = 0, SIGMA = 1, MU = 0.
%
%   C'est la loi limite du maximum d'un grand nombre d'observations,
%   quelle que soit leur loi de départ — c'est le théorème de
%   Fisher-Tippett, qui fait de la GEV pour les maxima ce que la normale
%   est pour les moyennes.
%
%   Exemples :
%      gevcdf(1, 0, 1, 0)            % 0.6922 : Gumbel
%      gevcdf(1, 0.5, 1, 0)          % Frechet
%      gevcdf(10, -0.5, 1, 0)        % 1 : la loi est bornee a 2
%
%   Voir aussi GEVPDF, GEVINV, GEVRND, EVCDF, WBLCDF.
    if nargin < 2 || isempty(k)
        k = 0;
    end
    if nargin < 3 || isempty(sigma)
        sigma = 1;
    end
    if nargin < 4 || isempty(mu)
        mu = 0;
    end
    [x, k, sigma, mu] = statAjuster(x, k, sigma, mu);
    p = zeros(size(x));
    for i = 1:numel(x)
        p(i) = unePlace(x(i), k(i), sigma(i), mu(i));
    end
end

function p = unePlace(x, k, sigma, mu)
%UNEPLACE La répartition en un point.
    if isnan(x) || isnan(k) || isnan(sigma) || isnan(mu) || sigma <= 0
        p = NaN;
        return;
    end
    z = (x - mu) / sigma;
    if k == 0
        p = exp(-exp(-z));
        return;
    end
    t = 1 + k * z;
    if t <= 0
        % Hors du support : la masse est toute d'un cote.
        p = double(k < 0);
        return;
    end
    p = exp(-t ^ (-1 / k));
end
