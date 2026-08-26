function w = blackmanharris(n)
%BLACKMANHARRIS Fenêtre de Blackman-Harris à quatre termes.
%   Coefficients : 0,35875 ; 0,48829 ; 0,14128 ; 0,01168.
    n = round(n);
    if n <= 1, w = ones(max(n, 0), 1); return, end
    k = (0:n-1)' / (n - 1);
    w = 0.35875 - 0.48829 * cos(2 * pi * k) + 0.14128 * cos(4 * pi * k) ...
        - 0.01168 * cos(6 * pi * k);
end
