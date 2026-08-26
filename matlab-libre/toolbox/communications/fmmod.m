function y = fmmod(x, Fc, Fs, deviation, phaseInitiale)
%FMMOD Modulation de fréquence.
%   Y = FMMOD(X,FC,FS,DEV) fait varier la fréquence instantanée de la
%   porteuse proportionnellement au signal :
%
%      y(t) = cos(2 pi FC t + 2 pi DEV integrale de x)
%
%   DEV est l'excursion en hertz par unité d'amplitude de X.
%   Y = FMMOD(X,FC,FS,DEV,PHI) décale la phase initiale.
%
%   Exemple :
%      t = (0:1999)' / 10000;
%      y = fmmod(sin(2*pi*30*t), 1000, 10000, 200);
%
%   Voir aussi FMDEMOD, AMMOD, PMMOD.
    if nargin < 5 || isempty(phaseInitiale), phaseInitiale = 0; end
    verifierFrequences(Fc, Fs);
    x = double(x);
    t = instants(x, Fs);
    % L'intégrale se calcule par somme cumulée, le pas valant 1/FS.
    integrale = cumsum(x) / Fs;
    y = cos(2 * pi * Fc * t + 2 * pi * deviation * integrale + phaseInitiale);
end
