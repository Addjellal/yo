function [b, a, k] = ellip(n, rp, rs, Wn, genre)
%ELLIP Filtre elliptique, ou filtre de Cauer.
%   [B,A] = ELLIP(N,RP,RS,WN) conçoit un passe-bas d'ordre N dont
%   l'ondulation en bande passante vaut RP décibels et l'atténuation en
%   bande coupée RS décibels ; WN est la fréquence de coupure
%   normalisée, 1 valant la moitié de la fréquence d'échantillonnage.
%   ELLIP(N,RP,RS,WN,'high') donne un passe-haut.
%
%   À ordre égal, l'elliptique est le filtre dont la transition est la
%   plus raide : il ondule dans les deux bandes, là où Chebyshev n'ondule
%   que dans l'une et Butterworth dans aucune.
%
%   Exemple :
%      [b, a] = ellip(4, 1, 40, 0.3);
%
%   Voir aussi ELLIPORD, BUTTER, CHEBY1, CHEBY2, BESSELF.
    if nargin < 5, genre = 'low'; end
    [z, p] = prototypeElliptique(n, rp, rs);
    if mod(n, 2) == 0
        reference = 10 ^ (-rp / 20);
    else
        reference = 1;
    end
    [b, a, zNum, pNum, kNum] = prototypeVersNumerique(p, z, 1, Wn, genre, reference);
    % Trois sorties : MATLAB rend alors la forme zéros-pôles-gain, dont la
    % conception numérique est plus stable que celle des coefficients.
    if nargout > 2
        b = zNum;
        a = pNum;
        k = kNum;
    end
end
