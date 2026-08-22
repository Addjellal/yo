function [margeModule, margeRetard] = stabilityMargin(sys)
%STABILITYMARGIN Marge de module et marge de retard d'une boucle ouverte.
%   La marge de module est la distance minimale du lieu de Nyquist au
%   point critique -1 ; la marge de retard s'en déduit par la marge de
%   phase et la pulsation de coupure.
    w = logspace(-4, 4, 8000).';
    [m, p] = bode(sys, w);
    h = m .* exp(1i * p * pi / 180);
    margeModule = min(abs(h + 1));
    [~, pm, ~, wc] = margin(sys);
    if isfinite(pm) && isfinite(wc) && wc > 0
        margeRetard = (pm * pi / 180) / wc;
    else
        margeRetard = inf;
    end
end
