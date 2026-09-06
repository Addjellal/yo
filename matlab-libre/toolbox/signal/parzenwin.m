function w = parzenwin(n)
%PARZENWIN Fenêtre de Parzen, ou de de la Vallée Poussin.
%   W = PARZENWIN(N) rend la fenêtre de N points, en colonne.
%
%   C'est la B-spline cubique : la convolution de quatre fenêtres
%   rectangulaires, d'où deux morceaux de polynômes de degré trois
%   raccordés à mi-pente. Chaque convolution multiplie le spectre par un
%   sinus cardinal, donc quatre convolutions font décroître les lobes
%   secondaires en 1/f^4, et la fenêtre est partout positive — son spectre
%   ne change jamais de signe, ce qu'aucune fenêtre de la famille cosinus
%   ne garantit.
%
%   Une densité spectrale estimée avec elle est donc toujours positive.
%   Le prix est le lobe principal, le plus large des fenêtres usuelles ;
%   ses lobes secondaires descendent en contrepartie à -53 dB.
%
%   Exemple :
%      w = parzenwin(64);
%      all(w >= 0)
%
%   Voir aussi BOHMANWIN, BARTLETT, BLACKMAN, HANN.
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
