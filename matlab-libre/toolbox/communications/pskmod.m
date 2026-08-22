function y = pskmod(x, M, phase)
%PSKMOD Modulation de phase à M états.
%   Y = PSKMOD(X,M) associe au symbole k le point exp(2i pi k / M).
    if nargin < 3
        phase = 0;
    end
    y = exp(1i * (2 * pi * x / M + phase));
end
