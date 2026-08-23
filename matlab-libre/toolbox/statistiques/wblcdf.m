function p = wblcdf(x, a, b)
%WBLCDF Répartition de la loi de Weibull.
    if nargin < 2, a = 1; end
    if nargin < 3, b = 1; end
    p = zeros(size(x));
    positif = x >= 0;
    p(positif) = 1 - exp(-(x(positif) ./ a).^b);
end
