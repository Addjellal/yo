function y = evpdf(x, mu, sigma)
%EVPDF Densité de la loi des valeurs extrêmes.
%   C'est la loi de Gumbel des minima, celle que MATLAB nomme « extreme
%   value » : y = exp(z)*exp(-exp(z))/sigma avec z = (x-mu)/sigma.
%
%   Exemple :  evpdf(0, 0, 1)   % exp(-1) = 0.3679
    if nargin < 2, mu = 0; end
    if nargin < 3, sigma = 1; end
    [x, mu, sigma] = statAjuster(x, mu, sigma);
    z = (x - mu) ./ sigma;
    y = exp(z - exp(z)) ./ sigma;
    y(sigma <= 0) = NaN;
end
