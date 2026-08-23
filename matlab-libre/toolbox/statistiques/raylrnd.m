function r = raylrnd(b, varargin)
%RAYLRND Tirages d'une loi de Rayleigh.
    if nargin < 1, b = 1; end
    forme = statForme(size(b), varargin);
    b = statEtendre(b, forme);
    r = b .* sqrt(-2 * log(rand(forme)));
    r(b <= 0) = NaN;
end
