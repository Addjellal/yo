function [stable, gains] = uncertainGain(sys, gains)
%UNCERTAINGAIN Stabilité en boucle fermée pour un gain incertain.
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
