function [psi, xval] = morlet(bas, haut, n)
%MORLET Ondelette de Morlet réelle.
%   [PSI,X] = MORLET(LB,UB,N) échantillonne sur N points de [LB,UB]
%
%      psi(x) = exp(-x^2/2) * cos(5x)
%
%   C'est la version réelle, non normalisée, de MATLAB : une sinusoïde de
%   pulsation cinq sous une enveloppe gaussienne. Sa moyenne n'est nulle
%   qu'à 1e-5 près — la condition d'admissibilité n'est vérifiée qu'en
%   pratique, ce qui est le défaut connu de Morlet réelle.
%
%   Exemple :
%      [psi, x] = morlet(-4, 4, 1000);
%
%   Voir aussi MEXIHAT, GAUSWAVF, CWT.
    if nargin < 1 || isempty(bas), bas = -8; end
    if nargin < 2 || isempty(haut), haut = 8; end
    if nargin < 3 || isempty(n), n = 1000; end
    xval = linspace(bas, haut, n);
    psi = exp(-xval .^ 2 / 2) .* cos(5 * xval);
end
