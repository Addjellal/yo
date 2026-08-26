function [L, P] = lqe(A, G, C, Q, R)
%LQE Estimateur linéaire quadratique : le gain du filtre de Kalman.
%   [L,P] = LQE(A,G,C,Q,R) résout l'équation de Riccati duale et rend le
%   gain L = P*C'/R, où P est la covariance d'estimation en régime
%   permanent.
%
%   Exemple :
%      L = lqe(0, 1, 1, 1, 1);   % 1
    if nargin < 5, R = eye(size(C, 1)); end
    [P, ~] = care(A', C', G * Q * G', R);
    L = P * C' / R;
end
