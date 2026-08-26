function [n, Wn] = buttord(Wp, Ws, Rp, Rs)
%BUTTORD Ordre minimal d'un filtre de Butterworth.
%   [N,WN] = BUTTORD(WP,WS,RP,RS) rend l'ordre le plus petit qui garde au
%   plus RP décibels d'ondulation jusqu'à WP et au moins RS décibels
%   d'atténuation à partir de WS. Les fréquences sont normalisées, 1 étant
%   la moitié de la fréquence d'échantillonnage.
%
%   Exemple :
%      [n, Wn] = buttord(0.2, 0.4, 1, 40);   % n = 8
    wp = tan(pi * Wp / 2);
    ws = tan(pi * Ws / 2);
    numerateur = log10((10^(Rs / 10) - 1) / (10^(Rp / 10) - 1));
    denominateur = 2 * log10(ws / wp);
    n = ceil(numerateur / denominateur);
    wnAnalogique = wp / (10^(Rp / 10) - 1)^(1 / (2 * n));
    Wn = 2 * atan(wnAnalogique) / pi;
end
