function [psi, xval] = fbspwavf(bas, haut, n, m, fb, fc)
%FBSPWAVF Ondelette spline en fréquence.
%   [PSI,X] = FBSPWAVF(LB,UB,N,M,FB,FC) échantillonne sur N points de
%   [LB,UB] l'ondelette
%
%      psi(x) = sqrt(FB) sinc(FB x / M)^M exp(2 i pi FC x),
%
%   où M est l'ordre du spline (entier au moins un, deux par défaut), FB
%   la largeur de bande (un par défaut) et FC la fréquence centrale (un
%   par défaut).
%
%   Élever le sinus cardinal à la puissance M revient à convoler la porte
%   avec elle-même M fois : la transformée est le spline d'ordre M, donc
%   toujours à support borné, mais de bords adoucis. M vaut un pour
%   l'ondelette de Shannon.
%
%   Exemple :
%      [psi, x] = fbspwavf(-20, 20, 1000, 2, 1, 1.5);
%      [shan, ~] = fbspwavf(-20, 20, 1000, 1, 1, 1.5);
%      max(abs(shan - shanwavf(-20, 20, 1000, 1, 1.5)))   % nul
%
%   Voir aussi SHANWAVF, CMORWAVF, CGAUWAVF, CWT.
    if nargin < 1 || isempty(bas), bas = -20; end
    if nargin < 2 || isempty(haut), haut = 20; end
    if nargin < 3 || isempty(n), n = 1000; end
    if nargin < 4 || isempty(m), m = 2; end
    if nargin < 5 || isempty(fb), fb = 1; end
    if nargin < 6 || isempty(fc), fc = 1; end
    m = round(m);
    if m < 1
        error('wavelet:fbspwavf:Ordre', 'L''ordre M doit valoir au moins un.');
    end
    if fb <= 0 || fc <= 0
        error('wavelet:fbspwavf:Parametres', 'FB et FC doivent être positifs.');
    end
    xval = linspace(bas, haut, n);
    psi = sqrt(fb) * sinc(fb * xval / m) .^ m .* exp(2 * 1i * pi * fc * xval);
end
