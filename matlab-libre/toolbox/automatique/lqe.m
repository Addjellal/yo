function [L, P] = lqe(A, G, C, Q, R)
%LQE Gain d'un estimateur linéaire quadratique.
%   [L,P,E] = LQE(A,G,C,Q,R) rend le gain L de l'observateur qui minimise
%   la variance de l'erreur d'estimation, la solution P de l'équation de
%   Riccati et les pôles E de l'observateur. Q est la covariance du bruit
%   d'état, R celle du bruit de mesure.
%
%   C'est le dual de LQR : plus le bruit de mesure est fort, plus le gain
%   est faible et l'estimateur prudent.
%
%   Exemples :
%      L = lqe(-1, 1, 1, 1, 1);
%      L > 0                                % vrai
%      max(real(eig(-1 - L * 1))) < -1      % l'observateur va plus vite
%
%   Voir aussi LQR, KALMAN, CARE, PLACE.
    if nargin < 5, R = eye(size(C, 1)); end
    [P, ~] = care(A', C', G * Q * G', R);
    L = P * C' / R;
end
