function [z, p, k] = ellipap(n, rp, rs)
%ELLIPAP Prototype analogique elliptique, ou de Cauer.
%   [Z,P,K] = ELLIPAP(N,RP,RS) rend les zéros, les pôles et le gain du
%   passe-bas analogique d'ordre N qui ondule de RP décibels en bande
%   passante et descend à RS décibels en bande atténuée ; le bord de
%   bande passante est en 1 radian par seconde.
%
%   À ordre égal, c'est la transition la plus raide qu'on puisse obtenir.
%
%   Exemple :
%      [z, p, k] = ellipap(4, 1, 40);
%
%   Voir aussi ELLIP, BUTTAP, CHEB1AP, CHEB2AP.
    [z, p] = prototypeElliptique(n, rp, rs);
    z = z(:);
    p = p(:);
    if isempty(z)
        k = real(prod(-p));
    else
        k = real(prod(-p) / prod(-z));
    end
    % Un ordre pair part du bas de l'ondulation, comme le type I.
    if mod(n, 2) == 0
        k = k * 10 ^ (-rp / 20);
    end
end
