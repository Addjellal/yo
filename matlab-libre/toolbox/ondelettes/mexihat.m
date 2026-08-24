function [psi, xval] = mexihat(bas, haut, n)
%MEXIHAT Ondelette « chapeau mexicain ».
%   [PSI,X] = MEXIHAT(LB,UB,N) échantillonne sur N points de [LB,UB] la
%   dérivée seconde de la gaussienne, normalisée à une norme deux
%   unitaire :
%
%      psi(x) = 2 / (sqrt(3) pi^(1/4)) * (1 - x^2) * exp(-x^2/2)
%
%   Elle a deux moments nuls et pas de fonction d'échelle : c'est une
%   ondelette de la transformée continue seulement.
%
%   Exemple :
%      [psi, x] = mexihat(-5, 5, 1000);
%      trapz(x, psi)          % nul : moyenne nulle
%      trapz(x, psi .^ 2)     % un
%
%   Voir aussi MORLET, GAUSWAVF, CWT.
    if nargin < 1 || isempty(bas), bas = -8; end
    if nargin < 2 || isempty(haut), haut = 8; end
    if nargin < 3 || isempty(n), n = 1000; end
    xval = linspace(bas, haut, n);
    psi = 2 / (sqrt(3) * pi ^ 0.25) * (1 - xval .^ 2) .* exp(-xval .^ 2 / 2);
end
