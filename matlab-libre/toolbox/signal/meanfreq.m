function f = meanfreq(x, fs)
%MEANFREQ Fréquence moyenne, pondérée par la puissance spectrale.
%   F = MEANFREQ(X,FS) rend le barycentre du spectre.
    if nargin < 2, fs = 1; end
    x = x(:);
    [pxx, freq] = periodogram(x, [], numel(x), fs);
    total = trapz(freq, pxx);
    if total <= 0
        f = 0;
    else
        f = trapz(freq, freq .* pxx) / total;
    end
end
