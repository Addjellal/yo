function [racines, gains] = rlocus(sys, gains)
%RLOCUS Lieu des racines de la boucle fermée.
%   [R,K] = RLOCUS(SYS) rend, pour une série de gains K, les pôles de
%   1 + K*SYS.
    g = tf(sys);
    if nargin < 2 || isempty(gains)
        gains = logspace(-2, 3, 200);
    end
    n = max(numel(g.den), numel(g.num)) - 1;
    racines = zeros(numel(gains), n);
    for k = 1:numel(gains)
        num = [zeros(1, numel(g.den) - numel(g.num)), g.num] * gains(k);
        den = g.den;
        p = roots(den + num);
        p = [p; zeros(n - numel(p), 1)];
        racines(k, :) = p(1:n).';
    end
    if nargout == 0
        plot(real(racines), imag(racines), '.');
        grid on;
        xlabel('Partie réelle');
        ylabel('Partie imaginaire');
        title('Lieu des racines');
    end
end
