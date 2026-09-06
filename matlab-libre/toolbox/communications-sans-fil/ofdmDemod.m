function symboles = ofdmDemod(signal, nfft, prefixe, nPorteuses)
%OFDMDEMOD Démodulation OFDM.
%   SYMBOLES = OFDMDEMOD(SIGNAL,NFFT,PREFIXE,NPORTEUSES) retire le préfixe
%   cyclique de chaque symbole, applique la transformée de Fourier et rend
%   les NPORTEUSES premières sous-porteuses.
%
%   Sans canal, la démodulation rend exactement les symboles modulés :
%   c'est la première vérification à faire, et elle prend une ligne.
%
%   Avec un canal, il reste à égaliser : diviser chaque porteuse par la
%   réponse du canal à sa fréquence. Un seul coefficient complexe par
%   porteuse suffit, ce qui est tout l'intérêt de l'OFDM face à un
%   égaliseur temporel.
%
%   Un préfixe plus court que la réponse du canal laisse passer
%   l'interférence entre symboles, que plus aucune égalisation ne défait :
%   c'est la limite que le dimensionnement doit respecter.
%
%   Exemple :
%      recus = ofdmDemod(signal, 64, 16, 48);
%      H = fft(canal, 64);
%      egalises = recus ./ H(1:48);
%
%   Voir aussi OFDMMOD, EVM.
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
