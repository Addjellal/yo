function [gainMarge, phaseMarge, wGain, wPhase] = margin(sys)
%MARGIN Marges de gain et de phase.
%   [GM,PM,WGM,WPM] = MARGIN(SYS) rend la marge de gain (linéaire), la
%   marge de phase (degrés) et les pulsations correspondantes.
    [m, p, w] = bode(sys, logspace(-4, 4, 4000).');
    dB = 20 * log10(m);
    % Marge de phase : pulsation où le gain traverse 0 dB.
    phaseMarge = inf;
    wPhase = NaN;
    for k = 1:numel(w)-1
        if dB(k) >= 0 && dB(k+1) < 0
            f = dB(k) / (dB(k) - dB(k+1));
            wPhase = w(k) + f * (w(k+1) - w(k));
            ph = p(k) + f * (p(k+1) - p(k));
            phaseMarge = 180 + ph;
            break;
        end
    end
    % Marge de gain : pulsation où la phase traverse -180 degrés.
    gainMarge = inf;
    wGain = NaN;
    for k = 1:numel(w)-1
        if (p(k) + 180) * (p(k+1) + 180) < 0
            f = (p(k) + 180) / (p(k) - p(k+1));
            wGain = w(k) + f * (w(k+1) - w(k));
            g = dB(k) + f * (dB(k+1) - dB(k));
            gainMarge = 10 ^ (-g / 20);
            break;
        end
    end
end
