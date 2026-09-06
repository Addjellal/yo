function x = dpskdemod(y, M, phase)
%DPSKDEMOD Démodulation par déplacement de phase différentiel.
%   X = DPSKDEMOD(Y,M) démodule un signal à déplacement de phase
%   différentiel à M états : le symbole n'est pas porté par la phase
%   absolue de chaque échantillon, mais par l'écart de phase avec
%   l'échantillon précédent. X = DPSKDEMOD(Y,M,PHASE) donne la phase de
%   référence du premier symbole, nulle par défaut.
%
%   L'écart est arrondi au multiple le plus proche de 2*pi/M, et le
%   résultat ramené dans 0..M-1.
%
%   Tout l'intérêt du différentiel est là : une rotation constante de la
%   constellation — un décalage de fréquence résiduel, une phase de canal
%   inconnue — s'annule dans la différence de deux symboles successifs. Le
%   récepteur n'a donc pas à récupérer la porteuse en phase, ce qui le
%   simplifie beaucoup.
%
%   Le prix est un doublement des erreurs : chaque symbole reçu sert de
%   référence au suivant, si bien qu'un bruit qui fausse un symbole en
%   fausse deux. À rapport signal sur bruit égal, le différentiel perd
%   environ 3 dB sur le cohérent.
%
%   Exemple :
%      y = dpskmod([0 1 2 3], 4);
%      dpskdemod(y, 4)'
%
%   Voir aussi DPSKMOD, PSKDEMOD, PSKMOD.
    if nargin < 3, phase = 0; end
    y = y(:);
    n = numel(y);
    x = zeros(n, 1);
    precedent = exp(1i * phase);
    for k = 1:n
        ecart = angle(y(k) / precedent);
        x(k) = mod(round(ecart * M / (2 * pi)), M);
        precedent = y(k);
    end
end
