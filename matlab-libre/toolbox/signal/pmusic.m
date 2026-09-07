function [S, f] = pmusic(x, p, nfft, fs)
%PMUSIC Pseudospectre par la méthode MUSIC.
%   [S,F] = PMUSIC(X,P,NFFT,FS) rend l'inverse de la projection du
%   vecteur directeur sur le sous-espace bruit : le pseudospectre monte
%   très haut aux fréquences présentes, mais ses valeurs ne sont pas des
%   puissances.
%
%   Exemple :
%      rng(1);
%      x = sin(2 * pi * 0.1 * (0:199)') + 0.1 * randn(200, 1);
%      [S, f] = pmusic(x, 4, 1024, 1000);
%      [~, k] = max(S);
%      abs(f(k) - 100) < 5      % 1 : le sous-espace signal trouve la raie
    if nargin < 3 || isempty(nfft), nfft = 256; end
    if nargin < 4 || isempty(fs), fs = 1; end
    [R, m] = signalMatriceCorrelation(x, p, false);
    [vecteurs, valeurs] = eig(R);
    [~, ordre] = sort(real(diag(valeurs)), 'descend');
    vecteurs = vecteurs(:, ordre);
    bruit = vecteurs(:, p+1:end);
    demi = floor(nfft / 2) + 1;
    f = (0:demi-1)' * fs / nfft;
    S = zeros(demi, 1);
    for j = 1:size(bruit, 2)
        spectre = abs(fft(conj(bruit(:, j)), nfft)) .^ 2;
        S = S + spectre(1:demi);
    end
    S = 1 ./ max(S, eps);
    m = m;                                     %#ok<ASGSL>
end
