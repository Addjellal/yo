function y = dct(x, n)
%DCT Transformée en cosinus discrète de type II, normalisée.
%   Y = DCT(X) applique la transformée utilisée par MATLAB :
%      y(k) = w(k) * sum_{m=1}^{N} x(m) cos(pi (2m-1)(k-1) / (2N))
%   avec w(1) = 1/sqrt(N) et w(k) = sqrt(2/N) sinon.
%
%   Exemple :
%      x = [1 2 3 4 5]';
%      max(abs(idct(dct(x)) - x)) < 1e-12     % 1 : la transformee est orthonormee
%
%   Voir aussi IDCT, DST.
    x = x(:);
    if nargin > 1 && ~isempty(n)
        if numel(x) > n
            x = x(1:n);
        else
            x = [x; zeros(n - numel(x), 1)];
        end
    end
    N = numel(x);
    y = zeros(N, 1);
    for k = 1:N
        s = 0;
        for m = 1:N
            s = s + x(m) * cos(pi * (2*m - 1) * (k - 1) / (2 * N));
        end
        if k == 1
            y(k) = s / sqrt(N);
        else
            y(k) = s * sqrt(2 / N);
        end
    end
end
