function [pxx, f] = pburg(x, p, nfft, fs)
%PBURG Densité spectrale par la méthode de Burg.
%   Même principe que PYULEAR, avec un modèle estimé par ARBURG : plus
%   sûr sur les séries courtes.
%
%   Exemple :
%      rng(1);
%      x = sin(2 * pi * 0.1 * (0:199)') + 0.1 * randn(200, 1);
%      [pxx, f] = pburg(x, 4, 128, 1);
%      numel(pxx) == numel(f)      % 1
    if nargin < 3 || isempty(nfft), nfft = 256; end
    if nargin < 4 || isempty(fs), fs = 1; end
    [a, e] = arburg(x, p);
    [pxx, f] = arSpectre(a, e, nfft, fs);
end
