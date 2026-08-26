function [f, xi] = ksdensity(x, points, varargin)
%KSDENSITY Estimation de densité par noyau.
%   [F,XI] = KSDENSITY(X) estime la densité de X sur 100 points. Le noyau
%   est gaussien et la largeur de bande suit la règle de Silverman :
%   1,06 * sigma * n^(-1/5).
%
%   Exemple :
%      [f, xi] = ksdensity(randn(1000, 1));
    x = x(:);
    x = x(~isnan(x));
    n = numel(x);
    largeur = [];
    for k = 1:2:numel(varargin) - 1
        if any(strcmpi(char(varargin{k}), {'Bandwidth', 'width'}))
            largeur = varargin{k + 1};
        end
    end
    if isempty(largeur)
        sigma = std(x);
        etendue = iqr(x) / 1.349;
        if etendue > 0, sigma = min(sigma, etendue); end
        largeur = 1.06 * sigma * n^(-1/5);
        if largeur <= 0, largeur = 1; end
    end
    if nargin < 2 || isempty(points)
        marge = 3 * largeur;
        xi = linspace(min(x) - marge, max(x) + marge, 100)';
    else
        xi = points(:);
    end
    f = zeros(size(xi));
    for k = 1:numel(xi)
        u = (xi(k) - x) / largeur;
        f(k) = sum(exp(-0.5 * u.^2)) / (n * largeur * sqrt(2 * pi));
    end
end
