function [m, v] = unifstat(a, b)
%UNIFSTAT Moyenne et variance de la loi uniforme continue.
%   Exemple :  [m,v] = unifstat(0, 1)   % 0.5 et 1/12
    if nargin < 1, a = 0; end
    if nargin < 2, b = 1; end
    [a, b] = statAjuster(a, b);
    m = (a + b) / 2;
    v = (b - a) .^ 2 / 12;
    m(a > b) = NaN;
    v(a > b) = NaN;
end
