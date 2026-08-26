function [pxx, f] = pcov(x, p, nfft, fs)
%PCOV Densité spectrale par la méthode de la covariance.
    if nargin < 3 || isempty(nfft), nfft = 256; end
    if nargin < 4 || isempty(fs), fs = 1; end
    [a, e] = arcov(x, p);
    [pxx, f] = arSpectre(a, e, nfft, fs);
end
