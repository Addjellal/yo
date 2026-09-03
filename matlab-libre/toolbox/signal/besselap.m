function [z, p, k] = besselap(n)
%BESSELAP Prototype analogique de Bessel.
%   [Z,P,K] = BESSELAP(N) rend les zéros, les pôles et le gain du
%   passe-bas analogique de Bessel d'ordre N, normalisé pour un retard
%   de groupe de 1 seconde en continu.
%
%   Il n'a aucun zéro fini ; ses pôles sont les racines du polynôme de
%   Bessel inverse, et le gain vaut 1 en continu.
%
%   Exemple :
%      [z, p, k] = besselap(3);
%
%   Voir aussi BESSELF, BUTTAP, CHEB1AP.
    n = round(n);
    if n < 1
        error('signal:besselap:BadOrder', 'L''ordre doit être au moins 1.');
    end
    [~, a] = besself(n, 1);
    z = zeros(0, 1);
    p = roots(a);
    k = real(prod(-p));
end
