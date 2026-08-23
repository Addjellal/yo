function y = lognpdf(x, mu, sigma)
%LOGNPDF Densité de la loi log-normale.
%   MU et SIGMA sont la moyenne et l'écart-type du logarithme.
    if nargin < 2, mu = 0; end
    if nargin < 3, sigma = 1; end
    x = double(x);
    y = zeros(size(x));
    positif = x > 0;
    y(positif) = exp(-(log(x(positif)) - mu).^2 ./ (2 * sigma.^2)) ./ ...
                 (x(positif) .* sigma .* sqrt(2 * pi));
end
