function signal = ofdmMod(symboles, nfft, prefixe)
%OFDMMOD Modulation OFDM avec préfixe cyclique.
%   SIGNAL = OFDMMOD(SYMBOLES,NFFT,PREFIXE) où SYMBOLES est une matrice
%   dont chaque colonne est un symbole OFDM. PREFIXE vaut NFFT/8 par
%   défaut.
%
%   L'OFDM répond au multitrajet en découpant la bande en sous-porteuses
%   assez étroites pour que chacune voie un canal plat. Chaque colonne de
%   symboles devient un symbole temporel par transformée de Fourier
%   inverse, précédé de sa propre fin — le préfixe cyclique.
%
%   Ce préfixe est ce qui fait tout marcher : tant qu'il est plus long que
%   la réponse du canal, la convolution linéaire du canal devient une
%   convolution circulaire, donc une simple multiplication porteuse par
%   porteuse en fréquence. Un seul coefficient par porteuse suffit alors à
%   annuler le canal.
%
%   Il rend aussi chaque symbole indépendant du précédent : le transitoire
%   du canal est contenu dans les premiers échantillons du préfixe, qui
%   sont jetés. Même le premier symbole est correct, sans rien avant lui.
%
%   Le coût est le débit : le préfixe n'apporte aucune information.
%
%   Exemple :
%      symboles = exp(1i * (pi/4 + randi([0 3], 48, 20) * pi/2));
%      signal = ofdmMod(symboles, 64, 16);
%      numel(signal)                   % 20 * (64 + 16)
%
%   Voir aussi OFDMDEMOD, EVM, RAYLEIGHCHANNEL.
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
