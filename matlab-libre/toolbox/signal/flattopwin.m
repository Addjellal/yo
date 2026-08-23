function w = flattopwin(n)
%FLATTOPWIN Fenêtre à sommet plat, pour la mesure d'amplitude.
%   Coefficients de MathWorks : 0,21557895 ; 0,41663158 ; 0,277263158 ;
%   0,083578947 ; 0,006947368.
    n = round(n);
    if n <= 1, w = ones(max(n, 0), 1); return, end
    k = (0:n-1)' / (n - 1);
    w = 0.21557895 - 0.41663158 * cos(2 * pi * k) + 0.277263158 * cos(4 * pi * k) ...
        - 0.083578947 * cos(6 * pi * k) + 0.006947368 * cos(8 * pi * k);
end
