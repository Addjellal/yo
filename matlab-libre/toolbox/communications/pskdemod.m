function x = pskdemod(y, M, phase, ordre)
%PSKDEMOD Démodulation de phase à M états, par décision du plus proche.
%   X = PSKDEMOD(Y,M) rend le symbole dont le point est le plus proche.
%   X = PSKDEMOD(Y,M,PHASE,ORDRE) reprend la phase et l'ordre employés à
%   la modulation ; ORDRE vaut 'bin' (défaut) ou 'gray'.
%
%   La décision est celle du plus proche voisin : sur un cercle, cela
%   revient à arrondir l'angle au multiple de 2 pi / M le plus proche.
%
%   Exemple :
%      x = pskdemod(pskmod([0 1 2 3], 4, pi / 4, 'gray'), 4, pi / 4, 'gray')
%
%   Voir aussi PSKMOD, QAMDEMOD.
    if nargin < 3 || isempty(phase)
        phase = 0;
    end
    if nargin < 4 || isempty(ordre)
        ordre = 'bin';
    end
    a = angle(y) - phase;
    position = mod(round(a * M / (2 * pi)), M);
    x = matlibre_comm_symbole(position, M, ordre);
end
