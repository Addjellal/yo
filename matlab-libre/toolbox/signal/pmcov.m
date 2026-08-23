function [pxx, f] = pmcov(x, p, nfft, fs)
%PMCOV Densité spectrale par la méthode de la covariance modifiée.
    if nargin < 3 || isempty(nfft), nfft = 256; end
    if nargin < 4 || isempty(fs), fs = 1; end
    [a, e] = armcov(x, p);
    [pxx, f] = arSpectre(a, e, nfft, fs);
end
