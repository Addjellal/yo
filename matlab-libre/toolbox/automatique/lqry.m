function [K, S, poles] = lqry(sys, Q, R, N)
%LQRY Commande linéaire quadratique pondérée sur la sortie.
%   [K,S,P] = LQRY(SYS,Q,R) minimise l'intégrale de y'Qy + u'Ru, où y est
%   la sortie du modèle. Comme y = Cx + Du, cela revient à un problème
%   pondéré sur l'état avec
%
%      Qx = C'QC,   Rx = R + D'QD,   Nx = C'QD
%
%   [K,S,P] = LQRY(SYS,Q,R,N) ajoute le terme croisé 2y'Nu.
%
%   Exemple :
%      lqry(ss(0, 1, 1, 0), 1, 1)   % 1
%
%   Voir aussi LQR, LQI, DLQR.
    s = ss(sys);
    if nargin < 4 || isempty(N), N = zeros(size(s.C, 1), size(s.B, 2)); end
    Qx = s.C' * Q * s.C;
    Rx = R + s.D' * Q * s.D;
    Nx = s.C' * (Q * s.D + N);
    Qx = (Qx + Qx') / 2;
    Rx = (Rx + Rx') / 2;
    if s.Ts == 0
        [K, S, poles] = lqr(s.A, s.B, Qx, Rx, Nx);
    else
        [K, S, poles] = dlqr(s.A, s.B, Qx, Rx, Nx);
    end
end
