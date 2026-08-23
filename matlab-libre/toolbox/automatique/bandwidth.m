function w = bandwidth(systeme, chute)
%BANDWIDTH Bande passante d'un système.
%   W = BANDWIDTH(SYS) rend la première pulsation où le gain descend de
%   3 décibels sous sa valeur en continu. BANDWIDTH(SYS,CHUTE) choisit
%   une autre chute, en décibels (négative).
%
%   Exemple :
%      bandwidth(tf(1, [1 1]))   % 1 rad/s
    if nargin < 2 || isempty(chute), chute = -3; end
    gainContinu = abs(dcgain(systeme));
    if gainContinu == 0 || ~isfinite(gainContinu)
        w = NaN;
        return
    end
    cible = gainContinu * 10^(chute / 20);
    bas = 1e-6;
    haut = 1e6;
    if abs(reponse(systeme, haut)) > cible
        w = Inf;
        return
    end
    for iteration = 1:200
        milieu = sqrt(bas * haut);
        if abs(reponse(systeme, milieu)) > cible
            bas = milieu;
        else
            haut = milieu;
        end
    end
    w = sqrt(bas * haut);
end

function h = reponse(systeme, omega)
    s = tf(systeme);
    h = polyval(s.num, 1i * omega) / polyval(s.den, 1i * omega);
end
