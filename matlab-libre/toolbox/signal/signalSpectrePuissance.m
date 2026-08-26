function [S, f] = signalSpectrePuissance(x, fs)
%SIGNALSPECTREPUISSANCE Spectre de puissance unilatéral, fenêtre de Kaiser.
%   Normalisé pour que la somme sur le lobe d'une sinusoïde d'amplitude A
%   rende A^2/2, sa puissance. La fenêtre de Kaiser à beta = 38 est celle
%   que MATLAB emploie pour ses mesures de distorsion : ses lobes
%   secondaires à -180 dB laissent voir des harmoniques très faibles.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
    if nargin < 2 || isempty(fs), fs = 1; end
    x = double(x(:));
    n = numel(x);
    w = kaiser(n, 38);
    X = fft(x .* w);
    m = floor(n / 2) + 1;
    % Normalisation de Parseval : la somme des |X|^2 vaut n fois l'energie
    % du signal fenetre, donc diviser par n*sum(w^2) rend la puissance.
    S = abs(X(1:m)) .^ 2 / (n * sum(w .^ 2));
    % Repliement de la moitié négative sur la moitié positive.
    S(2:end - (mod(n, 2) == 0)) = 2 * S(2:end - (mod(n, 2) == 0));
    f = (0:m-1)' * fs / n;
end
