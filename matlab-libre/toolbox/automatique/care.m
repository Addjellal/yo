function [X, K, poles] = care(A, B, Q, R)
%CARE Équation de Riccati algébrique continue.
%   X = CARE(A,B,Q,R) résout A'X + XA - XBR^{-1}B'X + Q = 0 et rend la
%   solution stabilisante : celle qui rend A - B*R^{-1}B'X stable. C'est
%   elle qui donne le gain optimal de la commande linéaire quadratique.
%
%   [X,K,P] = CARE(...) rend en plus K = R^{-1}B'X et les pôles P de la
%   boucle fermée.
%
%   La solution vient du sous-espace propre stable de la matrice
%   hamiltonienne associée.
%
%   Exemples :
%      care(0, 1, 1, 1)                 % 1
%      [X, K] = care([0 1; 0 0], [0; 1], eye(2), 1);
%      max(real(eig([0 1; 0 0] - [0; 1] * K))) < 0     % la boucle est stable
%
%   Voir aussi DARE, LQR, LYAP, HINFSYN.
    if nargin < 4 || isempty(R), R = eye(size(B, 2)); end
    n = size(A, 1);
    H = [A, -B * (R \ B'); -Q, -A'];
    [V, D] = eig(H);
    valeurs = diag(D);
    stable = real(valeurs) < 0;
    if sum(stable) ~= n
        % Pôles sur l'axe imaginaire : on prend les n plus à gauche, ce
        % qui reste la meilleure solution disponible.
        [~, ordre] = sort(real(valeurs));
        choix = ordre(1:n);
    else
        choix = find(stable);
    end
    U = V(:, choix);
    X1 = U(1:n, :);
    X2 = U(n+1:end, :);
    X = real(X2 / X1);
    X = (X + X') / 2;
    K = R \ (B' * X);
    poles = eig(A - B * K);
end
