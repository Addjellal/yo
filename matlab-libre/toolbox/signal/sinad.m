function [r, puissanceTotale] = sinad(x, fs)
%SINAD Rapport signal sur bruit et distorsion, en décibels.
%   R = SINAD(X) compare la puissance du fondamental à celle de tout le
%   reste, harmoniques et bruit confondus, la composante continue exclue.
%
%   Exemple :
%      t = (0:999)'/1000;
%      sinad(cos(2*pi*50*t) + 0.1*cos(2*pi*100*t))   % environ 20 dB
    if nargin < 2 || isempty(fs), fs = 1; end
    [S, ~] = signalSpectrePuissance(x, fs);
    [~, plageContinue] = signalLobe(S, 1);
    S(plageContinue) = 0;
    puissanceTotale = sum(S);
    [~, kf] = max(S);
    puissanceFondamental = signalLobe(S, kf);
    reste = puissanceTotale - puissanceFondamental;
    if reste <= 0
        r = Inf;
        return
    end
    r = 10 * log10(puissanceFondamental / reste);
end
