function w = barthannwin(n)
%BARTHANNWIN Fenêtre de Bartlett-Hann.
    n = round(n);
    if n <= 1, w = ones(max(n, 0), 1); return, end
    k = (0:n-1)' / (n - 1);
    w = 0.62 - 0.48 * abs(k - 0.5) + 0.38 * cos(2 * pi * (k - 0.5));
end
