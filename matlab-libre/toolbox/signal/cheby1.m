function [b, a] = cheby1(n, rp, Wn, genre)
%CHEBY1 Filtre de Chebyshev de type I.
%   [B,A] = CHEBY1(N,RP,WN) conçoit un passe-bas d'ordre N dont
%   l'ondulation en bande passante vaut RP décibels ; WN est la fréquence
%   de coupure normalisée, 1 correspondant à la moitié de la fréquence
%   d'échantillonnage.
%   CHEBY1(N,RP,WN,'high') donne un passe-haut.
%
%   Le prototype analogique est transformé par la bilinéaire, avec
%   pré-distorsion de la fréquence, comme le fait MATLAB.
%
%   Exemple :
%      [b, a] = cheby1(2, 1, 0.3);
%
%   Voir aussi BUTTER, CHEBY2, FIR1.
    if nargin < 4, genre = 'low'; end
    epsilon = sqrt(10^(rp / 10) - 1);
    % Pôles du prototype analogique, sur une ellipse.
    mu = asinh(1 / epsilon) / n;
    k = 1:n;
    theta = pi * (2 * k - 1) / (2 * n);
    poles = -sinh(mu) * sin(theta) + 1i * cosh(mu) * cos(theta);
    gain = prod(-poles);
    if mod(n, 2) == 0
        gain = gain / sqrt(1 + epsilon^2);
    end
    % Un Chebyshev de type I d'ordre pair ne vaut pas 1 en continu : il
%   part du bas de l'ondulation, à -RP décibels.
    if mod(n, 2) == 0
        reference = 10^(-rp / 20);
    else
        reference = 1;
    end
    [b, a] = prototypeVersNumerique(poles, [], gain, Wn, genre, reference);
end
