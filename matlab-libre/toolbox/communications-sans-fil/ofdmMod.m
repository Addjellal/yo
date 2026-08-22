function signal = ofdmMod(symboles, nfft, prefixe)
%OFDMMOD Modulation OFDM avec préfixe cyclique.
%   SIGNAL = OFDMMOD(SYMBOLES,NFFT,PREFIXE) où SYMBOLES est une matrice
%   dont chaque colonne est un symbole OFDM.
    if nargin < 3
        prefixe = round(nfft / 8);
    end
    [n, m] = size(symboles);
    signal = [];
    for k = 1:m
        colonne = zeros(nfft, 1);
        colonne(1:n) = symboles(:, k);
        temps = ifft(colonne, nfft) * sqrt(nfft);
        signal = [signal; temps(end-prefixe+1:end); temps];
    end
end
