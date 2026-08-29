function [K, S, poles] = lqr(A, B, Q, R, N)
%LQR Commande linéaire quadratique en temps continu.
%   [K,S,P] = LQR(A,B,Q,R) minimise l'intégrale de x'Qx + u'Ru sous
%   dx/dt = Ax + Bu, et rend le gain K du retour u = -Kx, la solution S
%   de l'équation de Riccati et les pôles P de la boucle fermée.
%
%   [K,S,P] = LQR(A,B,Q,R,N) ajoute le terme croisé 2x'Nu au coût. Il se
%   ramène au cas sans terme croisé en posant
%      Atilde = A - B R^{-1} N',   Qtilde = Q - N R^{-1} N',
%   puis K = R^{-1} (B'S + N').
%
%   LQR(SYS,Q,R,N) accepte aussi un modèle d'état.
%
%   Exemple :
%      lqr(0, 1, 1, 1)   % 1 : le gain qui place le pôle en -1
%
%   Voir aussi CARE, DLQR, LQRY, LQI.
    if isa(A, 'ss') || isa(A, 'tf')
        systeme = ss(A);
        if nargin >= 4, N = R; else, N = []; end
        R = Q;
        Q = B;
        B = systeme.B;
        A = systeme.A;
        if isempty(N), N = zeros(size(B)); end
    elseif nargin < 5 || isempty(N)
        N = zeros(size(B));
    end
    if nargin < 4 || isempty(R), R = eye(size(B, 2)); end
    Atilde = A - B * (R \ N');
    Qtilde = Q - N * (R \ N');
    S = care(Atilde, B, Qtilde, R);
    K = R \ (B' * S + N');
    if nargout > 2
        poles = eig(A - B * K);
    end
end
