function y = pammod(x, M, phaseInitiale, ordreSymboles)
%PAMMOD Modulation d'amplitude d'impulsions.
%   Y = PAMMOD(X,M) place l'entier X, compris entre 0 et M-1, sur la
%   constellation régulière {-(M-1), ..., -1, 1, ..., M-1} :
%
%      y = 2 x - M + 1
%
%   Y = PAMMOD(X,M,PHI) fait tourner la constellation de PHI radians.
%   Y = PAMMOD(X,M,PHI,'gray') interprète X comme un indice de Gray :
%   deux points voisins ne diffèrent alors que d'un bit, ce qui divise
%   par log2(M) le taux d'erreur binaire à taux d'erreur symbole égal.
%
%   Exemple :
%      pammod(0:3, 4)   % [-3 -1 1 3]
%
%   Voir aussi PAMDEMOD, QAMMOD, PSKMOD, BIN2GRAY.
    if nargin < 3 || isempty(phaseInitiale), phaseInitiale = 0; end
    if nargin < 4 || isempty(ordreSymboles), ordreSymboles = 'bin'; end
    x = double(x);
    if any(x(:) < 0) || any(x(:) > M - 1) || any(x(:) ~= round(x(:)))
        error('comm:pammod:BadSymbol', ...
              'Les symboles doivent être des entiers entre 0 et %d.', M - 1);
    end
    if strncmpi(char(ordreSymboles), 'gray', 4)
        x = gray2bin(x, 'pam', M);
    end
    y = 2 * x - M + 1;
    if phaseInitiale ~= 0
        y = y * exp(1i * phaseInitiale);
    end
end
