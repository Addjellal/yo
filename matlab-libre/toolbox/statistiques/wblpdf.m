function y = wblpdf(x, a, b)
%WBLPDF Densité de la loi de Weibull, d'échelle A et de forme B.
%   Exemple :  wblpdf(1, 1, 1)   % exp(-1)
    if nargin < 2, a = 1; end
    if nargin < 3, b = 1; end
    x = double(x);
    y = zeros(size(x));
    positif = x >= 0;
    z = x(positif) ./ a;
    y(positif) = (b ./ a) .* z.^(b - 1) .* exp(-z.^b);
end
