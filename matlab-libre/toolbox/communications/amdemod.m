function x = amdemod(y, Fc, Fs, phaseInitiale, amplitudePorteuse, num, den)
%AMDEMOD Démodulation d'amplitude cohérente.
%   X = AMDEMOD(Y,FC,FS) multiplie le signal reçu par la porteuse locale
%   puis filtre : le produit de deux cosinus donne la somme cherchée et
%   une composante au double de la fréquence, que le passe-bas retire.
%
%   X = AMDEMOD(Y,FC,FS,PHI,A) retranche ensuite la porteuse d'amplitude A.
%   X = AMDEMOD(Y,FC,FS,PHI,A,NUM,DEN) impose le filtre passe-bas ; par
%   défaut c'est un Butterworth d'ordre cinq coupant à FC.
%
%   Exemple :
%      t = (0:999)' / 8000;
%      m = sin(2*pi*50*t);
%      max(abs(amdemod(ammod(m, 1000, 8000), 1000, 8000) - m))   % petit
%
%   Voir aussi AMMOD, FMDEMOD, PMDEMOD.
    if nargin < 4 || isempty(phaseInitiale), phaseInitiale = 0; end
    if nargin < 5 || isempty(amplitudePorteuse), amplitudePorteuse = 0; end
    verifierFrequences(Fc, Fs);
    y = double(y);
    t = instants(y, Fs);
    produit = y .* cos(2 * pi * Fc * t + phaseInitiale) * 2;
    if nargin < 7 || isempty(num) || isempty(den)
        [num, den] = butter(5, Fc * 2 / Fs);
    end
    x = zeros(size(produit));
    for colonne = 1:size(produit, 2)
        x(:, colonne) = filter(num, den, produit(:, colonne));
    end
    x = x - amplitudePorteuse;
end
