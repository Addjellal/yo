function [m, v] = normstat(mu, sigma)
%NORMSTAT Moyenne et variance de la loi normale.
%   Exemple :  [m,v] = normstat(3, 2)   % 3 et 4
    if nargin < 1, mu = 0; end
    if nargin < 2, sigma = 1; end
    [mu, sigma] = statAjuster(mu, sigma);
    m = mu;
    v = sigma .^ 2;
    m(sigma <= 0) = NaN;
    v(sigma <= 0) = NaN;
end
