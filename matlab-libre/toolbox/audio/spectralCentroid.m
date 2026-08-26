function c = spectralCentroid(x, fs)
%SPECTRALCENTROID Centre de gravité du spectre, en hertz.
    if nargin < 2
        fs = 1;
    end
    x = x(:);
    n = numel(x);
    X = abs(fft(x));
    moitie = floor(n / 2) + 1;
    X = X(1:moitie);
    f = (0:moitie-1).' * fs / n;
    d = sum(X);
    if d == 0
        c = 0;
    else
        c = sum(f .* X) / d;
    end
end
