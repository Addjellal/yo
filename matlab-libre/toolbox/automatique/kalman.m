function [estimateur, L, P] = kalman(systeme, Q, R)
%KALMAN Filtre de Kalman d'un modèle d'état.
%   [KEST,L,P] = KALMAN(SYS,QN,RN) rend l'estimateur optimal de l'état,
%   le gain L et la covariance P de l'erreur, pour un bruit d'état de
%   covariance QN et un bruit de mesure de covariance RN.
%
%   L'estimateur suit xchapeau' = A*xchapeau + B*u + L*(y - C*xchapeau) :
%   il corrige sa prédiction proportionnellement à l'écart constaté.
%
%   Exemples :
%      [kest, L] = kalman(ss(-1, 1, 1, 0), 1, 1);
%      L > 0                                % le gain corrige dans le bon sens
%      max(real(eig(-1 - L))) < 0           % l'observateur converge
%
%   Voir aussi LQE, LQR, LQG, CARE, ESTIM.
    A = systeme.A;
    B = systeme.B;
    C = systeme.C;
    D = systeme.D;
    n = size(A, 1);
    [L, P] = lqe(A, eye(n), C, Q, R);
    % L'estimateur prend [u; y] en entrée et rend [y estimé; état estimé].
    Ae = A - L * C;
    Be = [B - L * D, L];
    Ce = [C; eye(n)];
    De = [D, zeros(size(C, 1), size(C, 1)); zeros(n, size(B, 2) + size(C, 1))];
    estimateur = ss(Ae, Be, Ce, De, systeme.Ts);
end
