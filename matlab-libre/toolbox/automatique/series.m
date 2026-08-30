function sys = series(sys1, sys2)
%SERIES Mise en série de deux modèles.
%   SYS = SERIES(SYS1,SYS2) met SYS1 devant SYS2 : la sortie du premier
%   entre dans le second. C'est SYS2*SYS1, l'ordre des facteurs suivant
%   celui du produit matriciel et non celui du schéma.
%
%   Les modèles à plusieurs voies sont acceptés : SYS1 doit avoir autant
%   de sorties que SYS2 a d'entrées.
%
%   Exemple :
%      L = series(tf(1, [1 1]), tf(10, [1 0]))   % 10/(s^2+s)
%
%   Voir aussi FEEDBACK, PARALLEL, APPEND, LFT.
    if matlibre_est_siso_tf(sys1) && matlibre_est_siso_tf(sys2)
        a = tf(sys1);
        b = tf(sys2);
        sys = tf(conv(a.num, b.num), conv(a.den, b.den), max(a.Ts, b.Ts));
        return
    end
    sys = ss(sys2) * ss(sys1);
end
