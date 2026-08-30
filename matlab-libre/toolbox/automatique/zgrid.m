function zgrid(zeta, wn)
%ZGRID Grille d'amortissement et de pulsation propre, plan discret.
%   ZGRID trace, dans le plan des z, le cercle unité, les spirales
%   d'amortissement constant et les courbes de pulsation propre constante.
%   C'est la grille du lieu des racines d'un système échantillonné.
%
%   ZGRID(ZETA,WN) ne trace que les valeurs demandées ; WN est normalisée
%   par la fréquence d'échantillonnage, entre 0 et 1.
%
%   Un pôle discret se lit par son image continue : z = exp(s*Ts), d'où
%   les spirales.
%
%   Exemples :
%      figure
%      pzmap(c2d(tf(1, [1 0.4 1]), 0.1));
%      zgrid
%      close
%
%   Voir aussi SGRID, NGRID, RLOCUS, PZMAP, C2D.
    if nargin < 1 || isempty(zeta)
        zeta = [0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9];
    end
    if nargin < 2 || isempty(wn)
        wn = 0.1:0.1:1;
    end
    bornesX = xlim();
    bornesY = ylim();
    tenu = ishold();
    hold on;
    % Le cercle unité : la frontière de stabilité.
    t = linspace(0, 2*pi, 200);
    plot(cos(t), sin(t), '-', 'Color', '#909090');
    % Les spirales d'amortissement constant, image des droites du plan s.
    for k = 1:numel(zeta)
        z = min(max(zeta(k), 0), 0.999);
        w = linspace(0, pi, 100);
        s = -z / sqrt(1 - z^2) * w + 1i * w;
        courbe = exp(s);
        plot(real(courbe), imag(courbe), ':', 'Color', '#B0B0B0');
        plot(real(courbe), -imag(courbe), ':', 'Color', '#B0B0B0');
    end
    % Les courbes de pulsation propre constante.
    for k = 1:numel(wn)
        z = linspace(0, 0.999, 100);
        s = -z ./ sqrt(1 - z.^2) * (wn(k) * pi) + 1i * (wn(k) * pi);
        courbe = exp(s);
        plot(real(courbe), imag(courbe), ':', 'Color', '#B0B0B0');
        plot(real(courbe), -imag(courbe), ':', 'Color', '#B0B0B0');
    end
    xlim(bornesX);
    ylim(bornesY);
    if ~tenu
        hold off;
    end
end
