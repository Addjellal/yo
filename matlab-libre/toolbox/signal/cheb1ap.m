function [z, p, k] = cheb1ap(n, rp)
%CHEB1AP Prototype analogique de Chebyshev de type I.
%   [Z,P,K] = CHEB1AP(N,RP) rend les zéros, les pôles et le gain du
%   passe-bas analogique d'ordre N qui ondule de RP décibels dans sa
%   bande passante ; le bord de bande est en 1 radian par seconde.
%
%   Il n'a aucun zéro fini : ses pôles sont sur une ellipse.
%
%   Exemple :
%      [z, p, k] = cheb1ap(4, 1);
%
%   Voir aussi CHEBY1, BUTTAP, CHEB2AP, ELLIPAP.
    n = round(n);
    if n < 1
        error('signal:cheb1ap:BadOrder', 'L''ordre doit être au moins 1.');
    end
    epsilon = sqrt(10 ^ (rp / 10) - 1);
    mu = asinh(1 / epsilon) / n;
    indices = 1:n;
    theta = (2 * indices - 1) * pi / (2 * n);
    p = (-sinh(mu) * sin(theta) + 1i * cosh(mu) * cos(theta)).';
    z = zeros(0, 1);
    k = real(prod(-p));
    % Un ordre pair ne vaut pas 1 en continu : il part du bas de
    % l'ondulation, comme dans MATLAB.
    if mod(n, 2) == 0
        k = k / sqrt(1 + epsilon ^ 2);
    end
end
