function w = parzenwin(n)
%PARZENWIN Fenêtre de Parzen, ou de de la Vallée Poussin.
    n = round(n);
    if n <= 1, w = ones(max(n, 0), 1); return, end
    k = (0:n-1)' - (n - 1) / 2;
    r = abs(k) / (n / 2);
    w = zeros(n, 1);
    centre = r <= 0.5;
    bord = ~centre;
    w(centre) = 1 - 6 * r(centre).^2 + 6 * r(centre).^3;
    w(bord) = 2 * (1 - r(bord)).^3;
end
