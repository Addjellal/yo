function [Pxx, f] = periodogram(x, fenetre, nfft, fs)
%PERIODOGRAM Densité spectrale de puissance par périodogramme.
%   [PXX,F] = PERIODOGRAM(X) estime la densité spectrale de X.
%   [PXX,F] = PERIODOGRAM(X,FENETRE,NFFT,FS) précise la fenêtre, la taille
%   de la transformée et la fréquence d'échantillonnage.
%
%   Exemple :
%      rng(1);
%      x = sin(2 * pi * 0.1 * (0:199)') + 0.1 * randn(200, 1);
%      [pxx, f] = periodogram(x, [], 512, 1);
%      [~, k] = max(pxx);
%      abs(f(k) - 0.1) < 0.02
%
%   Voir aussi PWELCH, PMTM, BANDPOWER.
    x = x(:);
    n = numel(x);
    if nargin < 2 || isempty(fenetre)
        fenetre = ones(n, 1);
    end
    fenetre = fenetre(:);
    if nargin < 3 || isempty(nfft)
        nfft = 2 ^ nextpow2(n);
    end
    if nargin < 4 || isempty(fs)
        fs = 1;
    end
    xw = x .* fenetre(1:n);
    X = fft(xw, nfft);
    U = sum(fenetre .^ 2);
    P = abs(X) .^ 2 / (U * fs);
    moitie = floor(nfft / 2) + 1;
    Pxx = P(1:moitie);
    Pxx(2:end-1) = 2 * Pxx(2:end-1);
    f = (0:moitie-1).' * fs / nfft;
end
