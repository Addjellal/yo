function [pxx, f] = arSpectre(a, e, nfft, fs, unilateral)
%ARSPECTRE Densité spectrale d'un modèle autorégressif.
%   Le modèle X = E/A(z) a pour densité e/(fs |A(f)|^2), doublée sur la
%   moitié positive du spectre quand on ne garde qu'un côté.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
    if nargin < 5, unilateral = true; end
    a = double(a(:)).';
    n = nfft;
    A = fft(a, n);
    densite = e ./ (fs * abs(A) .^ 2);
    if unilateral
        m = floor(n / 2) + 1;
        pxx = densite(1:m).';
        pxx(2:end - (mod(n, 2) == 0)) = 2 * pxx(2:end - (mod(n, 2) == 0));
        f = (0:m-1)' * fs / n;
    else
        pxx = densite(:);
        f = (0:n-1)' * fs / n;
    end
end
