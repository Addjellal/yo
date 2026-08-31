function x = gevinv(p, k, sigma, mu)
%GEVINV Quantile de la loi généralisée des valeurs extrêmes.
%   X = GEVINV(P,K,SIGMA,MU) rend le quantile d'ordre P de la loi GEV.
%   La forme est close :
%
%      x = mu + sigma * ((-log p)^(-k) - 1) / k        si k ~= 0
%      x = mu - sigma * log(-log p)                    si k = 0
%
%   Les arguments par défaut sont K = 0, SIGMA = 1, MU = 0.
%
%   Exemples :
%      gevinv(0.99, 0, 1, 0)         % le niveau de retour centennal
%      gevcdf(gevinv(0.7, 0.3), 0.3) % rend 0.7
%
%   Voir aussi GEVCDF, GEVPDF, GEVRND, EVINV, WBLINV.
    if nargin < 2 || isempty(k)
        k = 0;
    end
    if nargin < 3 || isempty(sigma)
        sigma = 1;
    end
    if nargin < 4 || isempty(mu)
        mu = 0;
    end
    [p, k, sigma, mu] = statAjuster(p, k, sigma, mu);
    x = zeros(size(p));
    for i = 1:numel(p)
        x(i) = unePlace(p(i), k(i), sigma(i), mu(i));
    end
end

function x = unePlace(p, k, sigma, mu)
%UNEPLACE Le quantile en un point.
    if isnan(p) || isnan(k) || isnan(sigma) || isnan(mu) || sigma <= 0 || ...
       p < 0 || p > 1
        x = NaN;
        return;
    end
    if p == 0
        % Le support est borne a gauche quand k est positif.
        if k > 0
            x = mu - sigma / k;
        else
            x = -Inf;
        end
        return;
    end
    if p == 1
        if k < 0
            x = mu - sigma / k;
        else
            x = Inf;
        end
        return;
    end
    if k == 0
        x = mu - sigma * log(-log(p));
        return;
    end
    x = mu + sigma * ((-log(p)) ^ (-k) - 1) / k;
end
