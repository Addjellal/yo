function [K, S, poles] = dlqr(A, B, Q, R, N)
%DLQR Commande linéaire quadratique en temps discret.
%   [K,S,P] = DLQR(A,B,Q,R) minimise la somme de x'Qx + u'Ru sous
%   x(k+1) = Ax(k) + Bu(k), et rend le gain K du retour u = -Kx, la
%   solution S de l'équation de Riccati discrète et les pôles P de la
%   boucle fermée.
%
%   [K,S,P] = DLQR(A,B,Q,R,N) ajoute le terme croisé 2x'Nu.
%
%   Exemple :
%      dlqr(1, 1, 1, 1)   % 0.6180 : l'inverse du nombre d'or
%
%   Voir aussi DARE, LQR, LQRD.
    if nargin < 4 || isempty(R), R = eye(size(B, 2)); end
    if nargin < 5 || isempty(N), N = zeros(size(B)); end
    Atilde = A - B * (R \ N');
    Qtilde = Q - N * (R \ N');
    S = dare(Atilde, B, Qtilde, R);
    K = (R + B' * S * B) \ (B' * S * A + N');
    if nargout > 2
        poles = eig(A - B * K);
    end
end
