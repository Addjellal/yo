function [pxx, f] = pmtm(x, nw, nfft, fs)
%PMTM Densité spectrale par la méthode multi-fenêtres de Thomson.
%   [PXX,F] = PMTM(X,NW,NFFT,FS) moyenne les périodogrammes obtenus avec
%   les 2*NW-1 premières fenêtres de Slepian, pondérés par leur taux de
%   concentration. NW vaut 4 par défaut.
%
%   Chaque fenêtre voit le signal autrement : la moyenne réduit la
%   variance de l'estimation sans élargir autant qu'un lissage.
%
%   Exemple :
%      [pxx, f] = pmtm(x, 4, 512, 1000);
    if nargin < 2 || isempty(nw), nw = 4; end
    x = double(x(:));
    n = numel(x);
    if nargin < 3 || isempty(nfft), nfft = max(256, 2 ^ nextpow2(n)); end
    if nargin < 4 || isempty(fs), fs = 1; end
    k = max(1, round(2 * nw - 1));
    [E, V] = dpss(n, nw, k);
    m = floor(nfft / 2) + 1;
    accumulateur = zeros(m, 1);
    for j = 1:size(E, 2)
        X = fft(x .* E(:, j), nfft);
        densite = abs(X(1:m)) .^ 2 / fs;
        accumulateur = accumulateur + V(j) * densite;
    end
    pxx = accumulateur / sum(V(1:size(E, 2)));
    pxx(2:end - (mod(nfft, 2) == 0)) = 2 * pxx(2:end - (mod(nfft, 2) == 0));
    f = (0:m-1)' * fs / nfft;
end
