function [y, t] = impulse(sys, tFinal)
%IMPULSE Réponse impulsionnelle.
    if nargin < 2
        [ys, t] = step(sys);
    else
        [ys, t] = step(sys, tFinal);
    end
    dt = t(2) - t(1);
    y = [0; diff(ys) / dt];
    if nargout == 0
        plot(t, y);
        grid on;
        title('Réponse impulsionnelle');
    end
end
