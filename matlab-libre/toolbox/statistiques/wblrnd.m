function r = wblrnd(a, b, varargin)
%WBLRND Tirages d'une loi de Weibull.
    if nargin < 1, a = 1; end
    if nargin < 2, b = 1; end
    forme = statForme(size(a + b), varargin);
    a = statEtendre(a, forme);
    b = statEtendre(b, forme);
    r = a .* (-log(rand(forme))) .^ (1 ./ b);
    r(a <= 0 | b <= 0) = NaN;
end
