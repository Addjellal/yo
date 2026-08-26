function w = gausswin(n, alpha)
%GAUSSWIN Fenêtre gaussienne.
%   W = GAUSSWIN(N,ALPHA) où ALPHA est l'inverse de l'écart-type, en
%   demi-largeurs. ALPHA vaut 2,5 par défaut.
%
%   W(k) = exp(-0.5 * (ALPHA * (2k/(N-1) - 1))^2).
    if nargin < 2, alpha = 2.5; end
    n = round(n);
    if n <= 1, w = ones(max(n, 0), 1); return, end
    k = (0:n-1)';
    r = 2 * k / (n - 1) - 1;
    w = exp(-0.5 * (alpha * r).^2);
end
