function x = pamdemod(y, M, phaseInitiale, ordreSymboles)
%PAMDEMOD Démodulation d'amplitude d'impulsions.
%   X = PAMDEMOD(Y,M) rend l'entier dont le point de constellation est le
%   plus proche de Y : la décision est un simple arrondi, la
%   constellation étant régulière de pas deux.
%
%   X = PAMDEMOD(Y,M,PHI) annule d'abord la rotation PHI.
%   X = PAMDEMOD(Y,M,PHI,'gray') rend l'indice de Gray.
%
%   Exemple :
%      pamdemod([-3 -0.9 1.2 3], 4)   % [0 1 2 3]
%
%   Voir aussi PAMMOD, QAMDEMOD, PSKDEMOD, BIN2GRAY.
    if nargin < 3 || isempty(phaseInitiale), phaseInitiale = 0; end
    if nargin < 4 || isempty(ordreSymboles), ordreSymboles = 'bin'; end
    y = double(y);
    if phaseInitiale ~= 0
        y = y * exp(-1i * phaseInitiale);
    end
    x = round((real(y) + M - 1) / 2);
    x = min(max(x, 0), M - 1);
    if strncmpi(char(ordreSymboles), 'gray', 4)
        x = bin2gray(x, 'pam', M);
    end
end
