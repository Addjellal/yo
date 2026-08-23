function [r, frequenceParasite] = sfdr(x, fs)
%SFDR Plage dynamique libre de parasites, en décibels.
%   R = SFDR(X) compare la puissance du fondamental à celle du plus fort
%   parasite, harmonique ou non.
%
%   Exemple :
%      t = (0:999)'/1000;
%      sfdr(cos(2*pi*50*t) + 0.01*cos(2*pi*130*t))   % environ 40 dB
    if nargin < 2 || isempty(fs), fs = 1; end
    [S, f] = signalSpectrePuissance(x, fs);
    [~, plageContinue] = signalLobe(S, 1);
    S(plageContinue) = 0;
    [~, kf] = max(S);
    [puissanceFondamental, plage] = signalLobe(S, kf);
    S(plage) = 0;
    [~, kp] = max(S);
    puissanceParasite = signalLobe(S, kp);
    frequenceParasite = f(kp);
    if puissanceParasite <= 0
        r = Inf;
        return
    end
    r = 10 * log10(puissanceFondamental / puissanceParasite);
end
