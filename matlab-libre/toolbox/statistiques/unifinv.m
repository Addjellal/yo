function x = unifinv(p, a, b)
%UNIFINV Quantile de la loi uniforme continue sur [A,B].
    if nargin < 2, a = 0; end
    if nargin < 3, b = 1; end
    [p, a, b] = statAjuster(p, a, b);
    x = a + p .* (b - a);
    x(p < 0 | p > 1 | a > b) = NaN;
end
