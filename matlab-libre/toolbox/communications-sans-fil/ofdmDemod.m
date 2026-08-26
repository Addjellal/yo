function symboles = ofdmDemod(signal, nfft, prefixe, nPorteuses)
%OFDMDEMOD Démodulation OFDM.
    if nargin < 3
        prefixe = round(nfft / 8);
    end
    if nargin < 4
        nPorteuses = nfft;
    end
    tailleSymbole = nfft + prefixe;
    m = floor(numel(signal) / tailleSymbole);
    symboles = zeros(nPorteuses, m);
    for k = 1:m
        bloc = signal((k-1)*tailleSymbole + prefixe + 1 : k*tailleSymbole);
        spectre = fft(bloc, nfft) / sqrt(nfft);
        symboles(:, k) = spectre(1:nPorteuses);
    end
end
