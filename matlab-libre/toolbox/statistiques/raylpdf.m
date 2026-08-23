function y = raylpdf(x, b)
%RAYLPDF Densité de la loi de Rayleigh de paramètre B.
%   Y = X/B^2 * exp(-X^2/(2*B^2)) pour X >= 0.
    if nargin < 2, b = 1; end
    x = double(x);
    y = zeros(size(x));
    positif = x >= 0;
    y(positif) = x(positif) ./ b.^2 .* exp(-x(positif).^2 ./ (2 * b.^2));
end
