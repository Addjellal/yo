function d = gevpdf(x, k, sigma, mu)
%GEVPDF Densité de la loi généralisée des valeurs extrêmes.
%   D = GEVPDF(X,K,SIGMA,MU) rend la densité de la loi GEV de paramètre
%   de forme K, d'échelle SIGMA et de position MU. La densité est nulle
%   hors du support, qui est borné d'un côté dès que K n'est pas nul.
%
%   Les arguments par défaut sont K = 0, SIGMA = 1, MU = 0.
%
%   Exemples :
%      gevpdf(0, 0, 1, 0)            % 0.3679 : le mode de Gumbel
%      x = linspace(-3, 6, 200);
%      plot(x, gevpdf(x, 0), x, gevpdf(x, 0.4), x, gevpdf(x, -0.4));
%
%   Voir aussi GEVCDF, GEVINV, GEVRND, EVPDF, WBLPDF.
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
    d = zeros(size(x));
    for i = 1:numel(x)
        d(i) = unePlace(x(i), k(i), sigma(i), mu(i));
    end
end

function d = unePlace(x, k, sigma, mu)
%UNEPLACE La densité en un point.
    if isnan(x) || isnan(k) || isnan(sigma) || isnan(mu) || sigma <= 0
        d = NaN;
        return;
    end
    z = (x - mu) / sigma;
    if k == 0
        d = exp(-z - exp(-z)) / sigma;
        return;
    end
    t = 1 + k * z;
    if t <= 0
        d = 0;
        return;
    end
    d = t ^ (-1 / k - 1) * exp(-t ^ (-1 / k)) / sigma;
end
