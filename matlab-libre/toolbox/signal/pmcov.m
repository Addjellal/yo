function [pxx, f] = pmcov(x, p, nfft, fs)
%PMCOV Densité spectrale par la méthode de la covariance modifiée.
%   PXX = PMCOV(X,P) estime la densité spectrale de X par un modèle
%   autorégressif d'ordre P ajusté par la méthode de la covariance
%   modifiée, puis évalue le spectre de ce modèle.
%   [PXX,F] = PMCOV(X,P,NFFT,FS) donne le nombre de points de la grille
%   (256 par défaut) et la fréquence d'échantillonnage.
%
%   « Modifiée » veut dire que l'ajustement minimise à la fois l'erreur de
%   prédiction avant et l'erreur arrière. Un signal stationnaire ayant les
%   mêmes statistiques lu à l'endroit et à l'envers, exiger les deux double
%   les équations sans ajouter d'inconnue : l'estimation est plus stable
%   sur un enregistrement court, et la résolution en fréquence meilleure.
%
%   C'est la méthode qui sépare le mieux deux sinusoïdes proches noyées
%   dans du bruit, quand on connaît l'ordre du modèle. Elle reste sensible
%   au choix de P : trop bas, les raies fusionnent ; trop haut, le bruit
%   engendre de fausses raies.
%
%   Exemple :
%      x = filter(1, [1 -0.9], randn(256, 1));
%      [pxx, f] = pmcov(x, 4, 128, 1);
%
%   Voir aussi PCOV, PBURG, PYULEAR, ARMCOV.
    if nargin < 3 || isempty(nfft), nfft = 256; end
    if nargin < 4 || isempty(fs), fs = 1; end
    [a, e] = armcov(x, p);
    [pxx, f] = arSpectre(a, e, nfft, fs);
end
