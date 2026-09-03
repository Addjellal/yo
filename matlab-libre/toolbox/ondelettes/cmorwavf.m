function [psi, xval] = cmorwavf(bas, haut, n, fb, fc)
%CMORWAVF Ondelette de Morlet complexe.
%   [PSI,X] = CMORWAVF(LB,UB,N,FB,FC) échantillonne sur N points de
%   [LB,UB] l'ondelette
%
%      psi(x) = 1/sqrt(pi FB) exp(2 i pi FC x) exp(-x^2 / FB),
%
%   où FB est le paramètre de largeur de bande (un par défaut) et FC la
%   fréquence centrale (un par défaut).
%
%   C'est une gaussienne modulée : sa transformée est une gaussienne
%   centrée sur FC. Plus FB est grand, plus l'ondelette est étalée en
%   temps et fine en fréquence — c'est le réglage du compromis.
%
%   Exemple :
%      [psi, x] = cmorwavf(-8, 8, 1000, 1.5, 1);
%      trapz(x, abs(psi) .^ 2)        % 1/sqrt(2 pi FB) : la norme deux
%
%   Voir aussi MORLET, CGAUWAVF, SHANWAVF, FBSPWAVF, CWT.
    if nargin < 1 || isempty(bas), bas = -8; end
    if nargin < 2 || isempty(haut), haut = 8; end
    if nargin < 3 || isempty(n), n = 1000; end
    if nargin < 4 || isempty(fb), fb = 1; end
    if nargin < 5 || isempty(fc), fc = 1; end
    if fb <= 0 || fc <= 0
        error('wavelet:cmorwavf:Parametres', ...
              'FB et FC doivent être positifs.');
    end
    xval = linspace(bas, haut, n);
    psi = ((pi * fb) ^ -0.5) * exp(2 * 1i * pi * fc * xval) .* exp(-xval .^ 2 / fb);
end
