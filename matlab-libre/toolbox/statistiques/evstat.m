function [m, v] = evstat(mu, sigma)
%EVSTAT Moyenne et variance de la loi des valeurs extrêmes.
%   La moyenne vaut mu - sigma*gamma d'Euler, la variance sigma^2*pi^2/6.
%
%   Exemple :  [m,v] = evstat(0, 1)   % -0.5772 et 1.6449
    if nargin < 1, mu = 0; end
    if nargin < 2, sigma = 1; end
    [mu, sigma] = statAjuster(mu, sigma);
    eulerGamma = 0.577215664901532860606512;
    m = mu - sigma * eulerGamma;
    v = sigma .^ 2 * pi ^ 2 / 6;
    m(sigma <= 0) = NaN;
    v(sigma <= 0) = NaN;
end
