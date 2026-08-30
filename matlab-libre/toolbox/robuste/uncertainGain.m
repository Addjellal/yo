function [stable, gains] = uncertainGain(sys, gains)
%UNCERTAINGAIN Stabilité en boucle fermée pour un gain incertain.
%   [STABLE,GAINS] = UNCERTAINGAIN(SYS) referme la boucle sur SYS
%   multiplié par une série de gains et dit, pour chacun, si la boucle
%   est stable. C'est l'analyse de robustesse la plus simple : celle
%   qu'on fait quand l'incertitude tient dans un seul paramètre.
%
%   UNCERTAINGAIN(SYS,GAINS) impose les gains à essayer.
%
%   Exemples :
%      [stable, gains] = uncertainGain(tf(1, [1 1]));
%      all(stable)                          % un premier ordre reste stable
%      s2 = uncertainGain(tf(1, [1 2 1 0]), [0.5 1 5]);
%      s2(1) && ~s2(3)                      % au-dela d'un certain gain, non
%
%   Voir aussi MARGIN, STABILITYMARGIN, FEEDBACK, RLOCUS.
    if nargin < 2
        gains = linspace(0.1, 10, 50);
    end
    stable = false(size(gains));
    for k = 1:numel(gains)
        g = tf(sys);
        boucle = feedback(tf(g.num * gains(k), g.den), tf(1, 1));
        stable(k) = all(real(roots(boucle.den)) < 0);
    end
end
