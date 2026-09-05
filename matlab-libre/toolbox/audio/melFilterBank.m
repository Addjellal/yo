function [banc, centres] = melFilterBank(nFiltres, nfft, fs)
%MELFILTERBANK Banc de filtres triangulaires sur l'échelle de Mel.
%   [BANC,CENTRES] = MELFILTERBANK(N,NFFT,FS) rend N filtres
%   triangulaires répartis sur l'échelle de Mel, chacun donné par ses
%   poids sur les NFFT/2+1 raies d'une transformée de Fourier, et leurs
%   fréquences centrales en hertz.
%
%   L'oreille ne perçoit pas les fréquences linéairement : deux sons
%   séparés de cent hertz s'entendent très différents dans les graves et
%   presque identiques dans les aigus. L'échelle de Mel épouse cette
%   perception —
%
%      mel = 2595 log10(1 + f / 700)
%
%   — si bien que des filtres régulièrement espacés en mel s'écartent de
%   plus en plus en hertz. C'est ce qui donne aux coefficients cepstraux
%   leur pertinence : ils résument le son comme l'oreille le résume.
%
%   Les filtres se recouvrent à mi-hauteur : chaque raie compte dans deux
%   filtres voisins, ce qui évite les discontinuités entre bandes.
%
%   Exemple :
%      [banc, centres] = melFilterBank(26, 512, 16000);
%      size(banc)                      % 26 par 257
%      diff(centres(1:3))              % petit ecart dans les graves
%      diff(centres(end-2:end))        % bien plus grand dans les aigus
%
%   Voir aussi MFCCSIMPLE, SPECTRALCENTROID, FFT.
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
