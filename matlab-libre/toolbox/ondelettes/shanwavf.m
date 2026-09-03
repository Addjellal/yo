function [psi, xval] = shanwavf(bas, haut, n, fb, fc)
%SHANWAVF Ondelette de Shannon complexe.
%   [PSI,X] = SHANWAVF(LB,UB,N,FB,FC) échantillonne sur N points de
%   [LB,UB] l'ondelette
%
%      psi(x) = sqrt(FB) sinc(FB x) exp(2 i pi FC x),
%
%   où sinc(x) = sin(pi x) / (pi x). FB est la largeur de bande (un par
%   défaut), FC la fréquence centrale (un par défaut).
%
%   Sa transformée est une porte : le support en fréquence est exactement
%   [FC - FB/2, FC + FB/2]. En échange elle décroît lentement en temps,
%   comme 1/x — c'est l'exact opposé de la gaussienne.
%
%   Exemple :
%      [psi, x] = shanwavf(-20, 20, 1000, 1, 1.5);
%      max(abs(imag(psi)))            % non nul : l'ondelette est complexe
%
%   Voir aussi FBSPWAVF, CMORWAVF, CGAUWAVF, CWT.
    if nargin < 1 || isempty(bas), bas = -20; end
    if nargin < 2 || isempty(haut), haut = 20; end
    if nargin < 3 || isempty(n), n = 1000; end
    if nargin < 4 || isempty(fb), fb = 1; end
    if nargin < 5 || isempty(fc), fc = 1; end
    if fb <= 0 || fc <= 0
        error('wavelet:shanwavf:Parametres', 'FB et FC doivent être positifs.');
    end
    xval = linspace(bas, haut, n);
    psi = sqrt(fb) * sinc(fb * xval) .* exp(2 * 1i * pi * fc * xval);
end
