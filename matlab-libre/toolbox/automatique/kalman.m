function [estimateur, L, P] = kalman(systeme, Q, R)
%KALMAN Filtre de Kalman en régime permanent.
%   [EST,L,P] = KALMAN(SYS,Q,R) rend le gain L, la covariance P et le
%   système estimateur dont l'état suit celui de SYS.
%
%   Le modèle est dx/dt = Ax + Bu + w, y = Cx + Du + v, avec w de
%   covariance Q et v de covariance R.
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
