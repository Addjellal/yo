function descripteurs = faultFeatures(signal, fs)
%FAULTFEATURES Descripteurs vibratoires : efficace, crête, kurtosis, centroïde.
    if nargin < 2
        fs = 1;
    end
    x = signal(:);
    descripteurs = struct();
    descripteurs.rms = sqrt(mean(x .^ 2));
    descripteurs.crete = max(abs(x));
    descripteurs.facteurCrete = descripteurs.crete / max(descripteurs.rms, eps);
    m = mean(x);
    e = std(x, 1);
    descripteurs.kurtosis = mean((x - m) .^ 4) / max(e ^ 4, eps);
    descripteurs.asymetrie = mean((x - m) .^ 3) / max(e ^ 3, eps);
    X = abs(fft(x));
    moitie = floor(numel(x) / 2) + 1;
    f = (0:moitie-1).' * fs / numel(x);
    descripteurs.centroide = sum(f .* X(1:moitie)) / max(sum(X(1:moitie)), eps);
end
