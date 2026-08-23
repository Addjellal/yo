function [s, f, t] = spectrogram(x, fenetre, recouvrement, nfft, fs)
%SPECTROGRAM Transformée de Fourier à court terme.
%   S = SPECTROGRAM(X,FENETRE,RECOUVREMENT,NFFT,FS) découpe X en tranches
%   pondérées par FENETRE, qui se recouvrent de RECOUVREMENT points, et
%   rend une colonne de spectre par tranche. Comme dans MATLAB, seules les
%   fréquences positives sont gardées pour un signal réel.
%
%   [S,F,T] = SPECTROGRAM(...) rend aussi l'axe des fréquences et celui
%   des instants, pris au centre de chaque tranche.
%
%   Exemple :
%      [s, f, t] = spectrogram(sin(2*pi*50*(0:999)/1000), 128, 64, 128, 1000);
    x = x(:);
    n = numel(x);
    if nargin < 2 || isempty(fenetre), fenetre = hamming(min(256, n)); end
    if isscalar(fenetre), fenetre = hamming(fenetre); end
    fenetre = fenetre(:);
    l = numel(fenetre);
    if nargin < 3 || isempty(recouvrement), recouvrement = floor(l / 2); end
    if nargin < 4 || isempty(nfft), nfft = max(256, 2^nextpow2(l)); end
    if nargin < 5 || isempty(fs), fs = 1; end
    pas = l - recouvrement;
    if pas < 1
        error('signal:spectrogram:BadOverlap', 'The overlap must be smaller than the window.');
    end
    debuts = 1:pas:(n - l + 1);
    colonnes = numel(debuts);
    demi = floor(nfft / 2) + 1;
    s = zeros(demi, max(colonnes, 0));
    for k = 1:colonnes
        tranche = x(debuts(k):debuts(k) + l - 1) .* fenetre;
        spectre = fft(tranche, nfft);
        s(:, k) = spectre(1:demi);
    end
    f = (0:demi-1)' * fs / nfft;
    t = (debuts(:) + (l - 1) / 2) / fs;
end
