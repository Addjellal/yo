function [S, f] = peig(x, p, nfft, fs)
%PEIG Pseudospectre par la méthode des vecteurs propres.
%   Comme PMUSIC, avec chaque vecteur du sous-espace bruit pondéré par
%   l'inverse de sa valeur propre.
    if nargin < 3 || isempty(nfft), nfft = 256; end
    if nargin < 4 || isempty(fs), fs = 1; end
    [R, m] = signalMatriceCorrelation(x, p, false);
    [vecteurs, valeurs] = eig(R);
    [valeurs, ordre] = sort(real(diag(valeurs)), 'descend');
    vecteurs = vecteurs(:, ordre);
    demi = floor(nfft / 2) + 1;
    f = (0:demi-1)' * fs / nfft;
    S = zeros(demi, 1);
    for j = p+1:m
        spectre = abs(fft(conj(vecteurs(:, j)), nfft)) .^ 2;
        S = S + spectre(1:demi) / max(valeurs(j), eps);
    end
    S = 1 ./ max(S, eps);
end
