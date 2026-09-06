function [pxx, f] = pcov(x, p, nfft, fs)
%PCOV Densité spectrale par la méthode de la covariance.
%   PXX = PCOV(X,P) estime la densité spectrale de X par un modèle
%   autorégressif d'ordre P ajusté par la méthode de la covariance, puis
%   évalue le spectre de ce modèle.
%   [PXX,F] = PCOV(X,P,NFFT,FS) donne le nombre de points de la grille
%   (256 par défaut) et la fréquence d'échantillonnage, et rend l'axe des
%   fréquences.
%
%   La méthode de la covariance minimise l'erreur de prédiction avant sur
%   les seuls échantillons où elle est calculable, sans supposer le signal
%   nul en dehors de la fenêtre observée. Elle ne fenêtre donc pas les
%   données — c'est ce qui la sépare de la méthode de Yule-Walker, dont
%   l'hypothèse implicite d'extension par des zéros élargit les raies sur
%   un enregistrement court.
%
%   La contrepartie est qu'elle ne garantit pas un modèle stable : un pôle
%   peut sortir du cercle unité. Le spectre reste lisible, mais le modèle
%   ne s'utilise pas tel quel pour synthétiser.
%
%   Exemple :
%      x = filter(1, [1 -0.9], randn(256, 1));
%      [pxx, f] = pcov(x, 4, 128, 1);
%
%   Voir aussi PMCOV, PYULEAR, PBURG, ARCOV.
    if nargin < 3 || isempty(nfft), nfft = 256; end
    if nargin < 4 || isempty(fs), fs = 1; end
    [a, e] = arcov(x, p);
    [pxx, f] = arSpectre(a, e, nfft, fs);
end
