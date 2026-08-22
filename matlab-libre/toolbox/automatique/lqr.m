function [K, S] = lqr(A, B, Q, R)
%LQR Commande linéaire quadratique en temps continu.
%   [K,S] = LQR(A,B,Q,R) minimise l'intégrale de x'Qx + u'Ru. S est la
%   solution de l'équation de Riccati, résolue par itération sur la
%   version discrétisée.
    n = size(A, 1);
    S = Q;
    dt = 0.001;
    Ad = eye(n) + A * dt;
    Bd = B * dt;
    for k = 1:200000
        Sn = Ad' * S * Ad - (Ad' * S * Bd) / (R + Bd' * S * Bd) * (Bd' * S * Ad) + Q * dt;
        if max(max(abs(Sn - S))) < 1e-12 * max(1, max(max(abs(S))))
            S = Sn;
            break;
        end
        S = Sn;
    end
    K = R \ (B' * S);
end
