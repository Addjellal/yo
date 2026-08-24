function [K, S, poles] = lqi(sys, Q, R, N)
%LQI Commande linéaire quadratique avec action intégrale.
%   [K,S,P] = LQI(SYS,Q,R) ajoute au modèle un état intégrateur par
%   sortie, dont la dérivée est l'écart de consigne :
%
%      dxi/dt = r - y = r - Cx - Du
%
%   puis résout le problème quadratique sur l'état augmenté [x; xi]. Le
%   retour u = -K [x; xi] annule l'erreur statique.
%
%   Q doit être carrée de taille NX+NY, R de taille NU.
%
%   Exemple :
%      k = lqi(ss(-1, 1, 1, 0), eye(2), 1);
%      numel(k)   % 2 : un gain d'état et un gain d'intégrateur
%
%   Voir aussi LQR, LQRY, LQE.
    s = ss(sys);
    n = size(s.A, 1);
    ny = size(s.C, 1);
    nu = size(s.B, 2);
    Aa = [s.A, zeros(n, ny); -s.C, zeros(ny, ny)];
    Ba = [s.B; -s.D];
    if nargin < 4 || isempty(N), N = zeros(n + ny, nu); end
    if s.Ts == 0
        [K, S, poles] = lqr(Aa, Ba, Q, R, N);
    else
        Aa = [s.A, zeros(n, ny); -s.C, eye(ny)];
        [K, S, poles] = dlqr(Aa, Ba, Q, R, N);
    end
end
