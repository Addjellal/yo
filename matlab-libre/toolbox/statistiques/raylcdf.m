function p = raylcdf(x, b)
%RAYLCDF Répartition de la loi de Rayleigh.
    if nargin < 2, b = 1; end
    p = zeros(size(x));
    positif = x >= 0;
    p(positif) = 1 - exp(-x(positif).^2 ./ (2 * b.^2));
end
