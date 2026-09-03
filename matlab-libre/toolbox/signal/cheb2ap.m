function [z, p, k] = cheb2ap(n, rs)
%CHEB2AP Prototype analogique de Chebyshev de type II.
%   [Z,P,K] = CHEB2AP(N,RS) rend les zéros, les pôles et le gain du
%   passe-bas analogique d'ordre N dont la bande atténuée descend à RS
%   décibels ; le bord de bande atténuée est en 1 radian par seconde.
%
%   Contrairement au type I, il porte des zéros sur l'axe imaginaire :
%   c'est ce qui creuse sa bande coupée.
%
%   Exemple :
%      [z, p, k] = cheb2ap(4, 40);
%
%   Voir aussi CHEBY2, BUTTAP, CHEB1AP, ELLIPAP.
    n = round(n);
    if n < 1
        error('signal:cheb2ap:BadOrder', 'L''ordre doit être au moins 1.');
    end
    epsilon = 1 / sqrt(10 ^ (rs / 10) - 1);
    mu = asinh(1 / epsilon) / n;
    indices = 1:n;
    theta = (2 * indices - 1) * pi / (2 * n);
    % Les pôles du type II sont l'inverse de ceux du type I.
    polesTypeI = -sinh(mu) * sin(theta) + 1i * cosh(mu) * cos(theta);
    p = (1 ./ polesTypeI).';
    if mod(n, 2) == 1
        % Le zéro du milieu part à l'infini : un ordre impair n'en a que
        % N-1 de finis.
        garde = [1:((n - 1) / 2), ((n + 3) / 2):n];
        z = (1i ./ cos(theta(garde))).';
    else
        z = (1i ./ cos(theta)).';
    end
    k = real(prod(-p) / prod(-z));
end
