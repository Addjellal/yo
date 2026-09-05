function y = pskmod(x, M, phase, ordre)
%PSKMOD Modulation de phase à M états.
%   Y = PSKMOD(X,M) associe au symbole k le point exp(2i pi k / M).
%   Y = PSKMOD(X,M,PHASE) fait tourner la constellation de PHASE radians.
%   Y = PSKMOD(X,M,PHASE,ORDRE) où ORDRE vaut 'bin' (défaut) ou 'gray'.
%
%   Tous les points sont sur le cercle unité : l'information est dans la
%   phase seule, si bien qu'un amplificateur saturé ne déforme pas le
%   signal — c'est la raison d'être de cette modulation.
%
%   En ordre binaire, le symbole k occupe la k-ième position autour du
%   cercle. En ordre de Gray, les positions successives portent des
%   valeurs qui ne diffèrent que d'un bit : une erreur entre deux points
%   voisins ne coûte alors qu'un bit faux au lieu de deux, ce qui divise
%   le taux d'erreur binaire sans rien coûter.
%
%   Exemple :
%      y = pskmod([0 1 2 3], 4, pi / 4, 'gray');
%      abs(y)                          % 1 partout
%
%   Voir aussi PSKDEMOD, QAMMOD, DE2BI.
    if nargin < 3 || isempty(phase)
        phase = 0;
    end
    if nargin < 4 || isempty(ordre)
        ordre = 'bin';
    end
    position = matlibre_comm_position(x, M, ordre);
    y = exp(1i * (2 * pi * position / M + phase));
end
