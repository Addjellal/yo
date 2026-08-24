function x = fmdemod(y, Fc, Fs, deviation, phaseInitiale)
%FMDEMOD Démodulation de fréquence.
%   X = FMDEMOD(Y,FC,FS,DEV) retrouve le signal modulant en dérivant la
%   phase instantanée. Celle-ci s'obtient par le signal analytique que
%   rend HILBERT : on retire la rampe de la porteuse, on déroule la
%   phase, puis on dérive.
%
%   Exemple :
%      t = (0:1999)' / 10000;
%      m = sin(2*pi*30*t);
%      max(abs(fmdemod(fmmod(m, 1000, 10000, 200), 1000, 10000, 200) - m))
%
%   Voir aussi FMMOD, AMDEMOD, PMDEMOD.
    if nargin < 5 || isempty(phaseInitiale), phaseInitiale = 0; end
    verifierFrequences(Fc, Fs);
    y = double(y);
    t = instants(y, Fs);
    x = zeros(size(y));
    for colonne = 1:size(y, 2)
        analytique = hilbert(y(:, colonne));
        phase = unwrap(angle(analytique(:))) - 2 * pi * Fc * t(:, min(colonne, size(t, 2))) - phaseInitiale;
        % Dérivée centrée à l'intérieur, décentrée aux bords.
        derivee = zeros(size(phase));
        derivee(2:end-1) = (phase(3:end) - phase(1:end-2)) * Fs / 2;
        derivee(1) = (phase(2) - phase(1)) * Fs;
        derivee(end) = (phase(end) - phase(end-1)) * Fs;
        x(:, colonne) = derivee / (2 * pi * deviation);
    end
end
