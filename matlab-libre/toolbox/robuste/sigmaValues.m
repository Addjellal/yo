function [valeurs, w] = sigmaValues(sys, w)
%SIGMAVALUES Valeurs singulières en décibels, sur une grille.
%   [SV,W] = SIGMAVALUES(SYS) rend le gain en décibels aux pulsations
%   d'une grille logarithmique, et la grille elle-même.
%   SIGMAVALUES(SYS,W) impose la grille.
%
%   C'est ce que trace SIGMA, rendu en nombres : de quoi comparer deux
%   modèles, chercher un maximum ou vérifier un gabarit sans passer par
%   une figure.
%
%   Exemples :
%      [sv, w] = sigmaValues(tf(1, [1 1]));
%      max(sv) <= 0.01                      % le gain ne depasse pas 0 dB
%      sv = sigmaValues(tf(1, [1 1]), 1);
%      abs(sv + 3.0103) < 1e-3              % -3 dB a la coupure
%
%   Voir aussi SIGMA, BODE, HINFNORM, FREQRESP.
    if nargin < 2
        w = logspace(-2, 3, 200).';
    end
    m = bode(sys, w);
    valeurs = 20 * log10(m);
end
