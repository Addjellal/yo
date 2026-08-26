function y = pmmod(x, Fc, Fs, deviation, phaseInitiale)
%PMMOD Modulation de phase.
%   Y = PMMOD(X,FC,FS,DEV) écrit le signal dans la phase de la porteuse :
%
%      y(t) = cos(2 pi FC t + DEV * x(t))
%
%   DEV est l'excursion de phase en radians par unité d'amplitude de X.
%
%   Exemple :
%      t = (0:1999)' / 10000;
%      y = pmmod(sin(2*pi*30*t), 1000, 10000, pi/4);
%
%   Voir aussi PMDEMOD, FMMOD, AMMOD.
    if nargin < 5 || isempty(phaseInitiale), phaseInitiale = 0; end
    verifierFrequences(Fc, Fs);
    x = double(x);
    t = instants(x, Fs);
    y = cos(2 * pi * Fc * t + deviation * x + phaseInitiale);
end
