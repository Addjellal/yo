function coefficients = mfccSimple(x, fs, nCoefficients)
%MFCCSIMPLE Coefficients cepstraux sur l'échelle de Mel.
    if nargin < 3
        nCoefficients = 13;
    end
    x = x(:);
    n = 2 ^ nextpow2(numel(x));
    X = abs(fft(x .* hamming(numel(x)), n));
    moitie = floor(n / 2) + 1;
    puissance = X(1:moitie) .^ 2 / n;
    banc = melFilterBank(26, n, fs);
    energies = log(max(banc * puissance, 1e-12));
    complet = dct(energies);
    coefficients = complet(1:min(nCoefficients, numel(complet)));
end
