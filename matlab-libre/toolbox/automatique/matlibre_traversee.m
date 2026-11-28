function [w, phase, module] = matlibre_traversee(sys, quoi, cible, wa, wb, pa, pb)
%MATLIBRE_TRAVERSEE Pulsation exacte d'une traversée que la grille a située.
%   [W, PHASE, MODULE] = MATLIBRE_TRAVERSEE(SYS, 'gain', 0, WA, WB, PA, PB)
%   rend la pulsation W, entre WA et WB, où le gain de SYS traverse 0 dB ;
%   MATLIBRE_TRAVERSEE(SYS, 'phase', CIBLE, ...) celle où sa phase
%   traverse CIBLE degrés. PA et PB sont les phases de la grille en WA et
%   WB : elles choisissent la branche de la phase rendue, à 360 degrés
%   près. MODULE est le gain en W, en valeur absolue.
%
%   La grille de MARGIN et d'ALLMARGIN ne fait que situer la traversée ;
%   l'interpolation linéaire entre deux de ses points la laisserait fausse
%   au millionième. La traversée se lit donc sur la réponse exacte, par
%   dichotomie, jusqu'à la précision des nombres.
%
%   Exemple :
%      sys = tf(1, [1 2 1 0]);
%      w = logspace(-1, 1, 50);
%      [~, p] = bode(sys, w);
%      k = find((p(1:end-1) + 180) .* (p(2:end) + 180) < 0, 1);
%      wg = matlibre_traversee(sys, 'phase', -180, w(k), w(k+1), p(k), p(k+1))   % 1
%
%   Voir aussi MARGIN, ALLMARGIN.
    if strcmp(quoi, 'gain')
        f = @(x) 20 * log10(moduleEn(sys, x)) - cible;
    else
        f = @(x) phaseEn(sys, x, pa, pb, wa, wb) - cible;
    end
    w = dichotomie(f, wa, wb);
    phase = phaseEn(sys, w, pa, pb, wa, wb);
    module = moduleEn(sys, w);
end

function x = dichotomie(f, a, b)
    fa = f(a);
    x = (a + b) / 2;
    for k = 1:200
        x = (a + b) / 2;
        if x <= a || x >= b
            break
        end
        fx = f(x);
        if fx == 0
            return
        end
        if sign(fx) == sign(fa)
            a = x;
            fa = fx;
        else
            b = x;
        end
    end
end

function m = moduleEn(sys, w)
    m = bode(sys, w);
    m = m(1);
end

% La phase exacte en W, ramenée à la branche de la grille : celle que
% l'interpolation entre (WA, PA) et (WB, PB) donne à 180 degrés près.
function ph = phaseEn(sys, w, pa, pb, wa, wb)
    [~, ph] = bode(sys, w);
    ph = ph(1);
    estime = pa + (w - wa) / (wb - wa) * (pb - pa);
    ph = ph + 360 * round((estime - ph) / 360);
end
