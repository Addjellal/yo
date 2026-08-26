function p = logncdf(x, mu, sigma)
%LOGNCDF Répartition de la loi log-normale.
    if nargin < 2, mu = 0; end
    if nargin < 3, sigma = 1; end
    p = zeros(size(x));
    positif = x > 0;
    p(positif) = normcdf((log(x(positif)) - mu) ./ sigma);
end
