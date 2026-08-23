function [pxx, f] = pburg(x, p, nfft, fs)
%PBURG Densité spectrale par la méthode de Burg.
%   Même principe que PYULEAR, avec un modèle estimé par ARBURG : plus
%   sûr sur les séries courtes.
    if nargin < 3 || isempty(nfft), nfft = 256; end
    if nargin < 4 || isempty(fs), fs = 1; end
    [a, e] = arburg(x, p);
    [pxx, f] = arSpectre(a, e, nfft, fs);
end
