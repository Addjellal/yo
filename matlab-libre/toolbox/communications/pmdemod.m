function x = pmdemod(y, Fc, Fs, deviation, phaseInitiale)
%PMDEMOD Démodulation de phase.
%   X = PMDEMOD(Y,FC,FS,DEV) retire la rampe de la porteuse à la phase du
%   signal analytique, déroule ce qui reste, et divise par l'excursion.
%
%   Exemple :
%      t = (0:1999)' / 10000;
%      m = sin(2*pi*30*t);
%      max(abs(pmdemod(pmmod(m, 1000, 10000, 1), 1000, 10000, 1) - m))
%
%   Voir aussi PMMOD, FMDEMOD, AMDEMOD.
    if nargin < 5 || isempty(phaseInitiale), phaseInitiale = 0; end
    verifierFrequences(Fc, Fs);
    y = double(y);
    t = instants(y, Fs);
    x = zeros(size(y));
    for colonne = 1:size(y, 2)
        analytique = hilbert(y(:, colonne));
        phase = unwrap(angle(analytique(:))) - 2 * pi * Fc * t(:, min(colonne, size(t, 2))) - phaseInitiale;
        x(:, colonne) = phase / deviation;
    end
end
