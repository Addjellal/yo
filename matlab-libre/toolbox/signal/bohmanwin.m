function w = bohmanwin(n)
%BOHMANWIN Fenêtre de Bohman.
    n = round(n);
    if n <= 1, w = ones(max(n, 0), 1); return, end
    k = (0:n-1)' - (n - 1) / 2;
    r = abs(k) / ((n - 1) / 2);
    w = (1 - r) .* cos(pi * r) + sin(pi * r) / pi;
    w(1) = 0;
    w(end) = 0;
end
