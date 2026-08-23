function w = nuttallwin(n)
%NUTTALLWIN Fenêtre de Blackman-Nuttall à quatre termes.
%   Coefficients : 0,3635819 ; 0,4891775 ; 0,1365995 ; 0,0106411.
    n = round(n);
    if n <= 1, w = ones(max(n, 0), 1); return, end
    k = (0:n-1)' / (n - 1);
    w = 0.3635819 - 0.4891775 * cos(2 * pi * k) + 0.1365995 * cos(4 * pi * k) ...
        - 0.0106411 * cos(6 * pi * k);
end
