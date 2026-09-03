function [z, p, k] = buttap(n)
%BUTTAP Prototype analogique de Butterworth.
%   [Z,P,K] = BUTTAP(N) rend les zéros, les pôles et le gain du filtre
%   passe-bas analogique de Butterworth d'ordre N, normalisé : sa
%   fréquence de coupure à −3 dB vaut 1 radian par seconde.
%
%   Il n'a aucun zéro fini ; ses N pôles sont régulièrement répartis sur
%   le demi-cercle unité gauche, et le gain vaut 1 en continu.
%
%   Exemple :
%      [z, p, k] = buttap(4);
%      abs(prod(-p))       % 1 : le gain en continu
%
%   Voir aussi BUTTER, CHEB1AP, CHEB2AP, ELLIPAP, BESSELAP, ZP2TF.
    n = round(n);
    if n < 1
        error('signal:buttap:BadOrder', 'L''ordre doit être au moins 1.');
    end
    z = zeros(0, 1);
    indices = 1:n;
    p = exp(1i * pi * (2 * indices - 1 + n) / (2 * n)).';
    % Les pôles vont par paires conjuguées : la partie imaginaire du pôle
    % réel d'un ordre impair doit être exactement nulle.
    if mod(n, 2) == 1
        p((n + 1) / 2) = -1;
    end
    k = real(prod(-p));
end
