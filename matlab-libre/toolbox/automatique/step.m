function [y, t] = step(sys, tFinal)
%STEP Réponse indicielle.
%   [Y,T] = STEP(SYS) simule la réponse à un échelon unité.
%   [Y,T] = STEP(SYS,TFINAL) impose l'horizon de simulation.
    if nargin < 2 || isempty(tFinal)
        p = pole(sys);
        vitesses = abs(real(p));
        vitesses = vitesses(vitesses > 1e-9);
        if isempty(vitesses)
            tFinal = 10;
        else
            tFinal = 8 / min(vitesses);
        end
        tFinal = min(max(tFinal, 1), 1000);
    end
    t = linspace(0, tFinal, 400).';
    u = ones(size(t));
    [y, t] = lsim(sys, u, t);
    if nargout == 0
        plot(t, y);
        grid on;
        xlabel('Temps (s)');
        ylabel('Amplitude');
        title('Réponse indicielle');
    end
end
