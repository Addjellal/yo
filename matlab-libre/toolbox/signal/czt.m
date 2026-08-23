function g = czt(x, m, w, a)
%CZT Transformée en Z sur une spirale (algorithme de Bluestein).
%   G = CZT(X,M,W,A) évalue la transformée en Z de X en M points pris sur
%   la spirale A*W^(-k). Avec M = N, W = exp(-2i*pi/N) et A = 1, c'est la
%   transformée de Fourier discrète.
%
%   Exemple :
%      n = 8; norm(czt(1:n) - fft((1:n)')) < 1e-10
    x = x(:);
    n = numel(x);
    if nargin < 2 || isempty(m), m = n; end
    if nargin < 3 || isempty(w), w = exp(-2i * pi / m); end
    if nargin < 4 || isempty(a), a = 1; end
    k = (0:max(m, n) - 1)';
    puissances = w .^ ((k.^2) / 2);
    y = x .* (a .^ -(0:n-1)') .* puissances(1:n);
    longueur = 2^nextpow2(n + m - 1);
    noyau = zeros(longueur, 1);
    noyau(1:m) = 1 ./ puissances(1:m);
    noyau(longueur - n + 2:longueur) = 1 ./ puissances(n:-1:2);
    convolution = ifft(fft(y, longueur) .* fft(noyau));
    g = convolution(1:m) .* puissances(1:m);
end
