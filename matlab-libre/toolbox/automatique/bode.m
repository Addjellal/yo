function [module, phase, w] = bode(sys, w)
%BODE Réponse fréquentielle : module et phase.
%   [MODULE,PHASE,W] = BODE(SYS) rend le module (linéaire) et la phase en
%   degrés. Sans sortie, la fonction trace les deux diagrammes.
    g = tf(sys);
    if nargin < 2 || isempty(w)
        p = [roots(g.den); roots(g.num)];
        p = p(abs(p) > 1e-9);
        if isempty(p)
            centre = 1;
        else
            centre = exp(mean(log(abs(p))));
        end
        w = logspace(log10(centre / 100), log10(centre * 100), 200).';
    end
    w = w(:);
    if g.Ts > 0
        s = exp(1i * w * g.Ts);
    else
        s = 1i * w;
    end
    h = polyval(g.num, s) ./ polyval(g.den, s);
    module = abs(h);
    phase = unwrap(angle(h)) * 180 / pi;
    if nargout == 0
        subplot(2, 1, 1);
        semilogx(w, 20 * log10(module));
        grid on;
        ylabel('Gain (dB)');
        title('Diagramme de Bode');
        subplot(2, 1, 2);
        semilogx(w, phase);
        grid on;
        xlabel('Pulsation (rad/s)');
        ylabel('Phase (deg)');
    end
end
