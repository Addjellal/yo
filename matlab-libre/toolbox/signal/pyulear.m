function [pxx, f] = pyulear(x, p, nfft, fs)
%PYULEAR Densité spectrale par un modèle autorégressif de Yule-Walker.
%   [PXX,F] = PYULEAR(X,P,NFFT,FS). Le spectre paramétrique n'a pas de
%   lobes de fuite : il est lisse, et sa résolution ne dépend pas de la
%   longueur de l'enregistrement mais de l'ordre choisi.
%
%   Exemple :
%      rng(1);
%      x = sin(2 * pi * 0.1 * (0:199)') + 0.1 * randn(200, 1);
%      [pxx, f] = pyulear(x, 8, 512, 1000);
%      [~, k] = max(pxx);
%      abs(f(k) - 100) < 10
%
%   Voir aussi PBURG, PCOV, ARYULE.
    if nargin < 3 || isempty(nfft), nfft = 256; end
    if nargin < 4 || isempty(fs), fs = 1; end
    [a, e] = aryule(x, p);
    [pxx, f] = arSpectre(a, e, nfft, fs);
end
