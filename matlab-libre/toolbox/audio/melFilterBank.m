function [banc, centres] = melFilterBank(nFiltres, nfft, fs)
%MELFILTERBANK Banc de filtres triangulaires sur l'échelle de Mel.
    melMax = 2595 * log10(1 + (fs / 2) / 700);
    points = linspace(0, melMax, nFiltres + 2);
    hertz = 700 * (10 .^ (points / 2595) - 1);
    bins = floor((nfft + 1) * hertz / fs);
    moitie = floor(nfft / 2) + 1;
    banc = zeros(nFiltres, moitie);
    for m = 1:nFiltres
        a = bins(m) + 1;
        b = bins(m + 1) + 1;
        c = bins(m + 2) + 1;
        for k = a:b
            if k >= 1 && k <= moitie && b > a
                banc(m, k) = (k - a) / (b - a);
            end
        end
        for k = b:c
            if k >= 1 && k <= moitie && c > b
                banc(m, k) = (c - k) / (c - b);
            end
        end
    end
    centres = hertz(2:end-1);
end
