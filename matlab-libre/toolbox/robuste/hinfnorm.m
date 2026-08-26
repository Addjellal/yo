function [gamma, pulsation] = hinfnorm(sys, tolerance)
%HINFNORM Norme H-infini, par balayage fréquentiel raffiné.
    if nargin < 2
        tolerance = 1e-6;
    end
    w = logspace(-4, 4, 4000);
    [m, ~, w] = bode(sys, w(:));
    [gamma, k] = max(m);
    pulsation = w(k);
    % Raffinement local autour du maximum.
    a = w(max(k-1, 1));
    b = w(min(k+1, numel(w)));
    for tour = 1:60
        milieu1 = a + (b - a) / 3;
        milieu2 = b - (b - a) / 3;
        m1 = max(bode(sys, milieu1));
        m2 = max(bode(sys, milieu2));
        if m1 < m2
            a = milieu1;
        else
            b = milieu2;
        end
        if b - a < tolerance * max(1, b)
            break;
        end
    end
    pulsation = (a + b) / 2;
    gamma = max(gamma, max(bode(sys, pulsation)));
end
