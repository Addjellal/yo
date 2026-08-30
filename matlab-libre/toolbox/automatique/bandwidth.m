function w = bandwidth(systeme, chute)
%BANDWIDTH Bande passante d'un modèle.
%   W = BANDWIDTH(SYS) rend la première pulsation où le gain descend de
%   trois décibels sous sa valeur en continu : la limite au-delà de
%   laquelle le système ne suit plus.
%
%   W = BANDWIDTH(SYS,CHUTE) choisit une autre chute, en décibels, donnée
%   négative.
%
%   Le gain statique doit être fini et non nul ; sinon la fonction rend
%   NaN, faute de référence à laquelle comparer.
%
%   Exemples :
%      bandwidth(tf(1, [1 1]))          % 1 rad/s
%      bandwidth(tf(1, [1 1]), -6)      % la pulsation a -6 dB
%
%   Voir aussi DCGAIN, BODE, MARGIN, STEPINFO.
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
