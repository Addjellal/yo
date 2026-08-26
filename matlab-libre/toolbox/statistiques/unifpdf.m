function y = unifpdf(x, a, b)
%UNIFPDF Densité de la loi uniforme continue sur [A,B].
    if nargin < 2, a = 0; end
    if nargin < 3, b = 1; end
    y = zeros(size(x));
    y(x >= a & x <= b) = 1 / (b - a);
end
