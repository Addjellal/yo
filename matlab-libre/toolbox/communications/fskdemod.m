function x = fskdemod(y, M, ecart, nEchantillons, fs)
%FSKDEMOD Démodulation par déplacement de fréquence, par corrélation.
%   X = FSKDEMOD(Y,M,ECART,NECHANTILLONS) démodule un signal à déplacement
%   de fréquence à M états, chaque symbole occupant NECHANTILLONS points et
%   les tons étant espacés de ECART. X = FSKDEMOD(Y,M,ECART,NECHANTILLONS,
%   FS) donne la fréquence d'échantillonnage, égale à un par défaut.
%
%   Le récepteur corrèle chaque bloc avec les M tons possibles et retient
%   celui de plus forte corrélation. Le module est pris avant comparaison :
%   la phase n'intervient pas, la détection est donc non cohérente et ne
%   demande aucune synchronisation de porteuse — seulement celle des
%   symboles.
%
%   Deux tons sont orthogonaux sur la durée d'un symbole si leur écart est
%   un multiple de la moitié de la cadence symbole en détection cohérente,
%   de la cadence entière en détection non cohérente. Un écart plus faible
%   fait déborder les corrélations les unes sur les autres, et le
%   démodulateur confond les tons voisins même sans bruit.
%
%   Exemple :
%      y = fskmod([0 1 2 3], 4, 2, 8, 16);
%      fskdemod(y, 4, 2, 8, 16)'
%
%   Voir aussi FSKMOD, PSKDEMOD, DPSKDEMOD.
    if nargin < 5, fs = 1; end
    y = y(:);
    n = floor(numel(y) / nEchantillons);
    x = zeros(n, 1);
    t = (0:nEchantillons-1)' / fs;
    for k = 1:n
        bloc = y((k-1)*nEchantillons + (1:nEchantillons));
        meilleur = -inf;
        for m = 0:M-1
            f = (2 * m - (M - 1)) * ecart / 2;
            correlation = abs(sum(bloc .* conj(exp(1i * 2 * pi * f * t))));
            if correlation > meilleur
                meilleur = correlation;
                x(k) = m;
            end
        end
    end
end
