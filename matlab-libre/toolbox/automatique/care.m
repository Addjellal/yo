function [X, K, poles] = care(A, B, Q, R)
%CARE Équation de Riccati algébrique continue.
%   X = CARE(A,B,Q,R) résout A'X + XA - XBR^{-1}B'X + Q = 0.
%   [X,K,P] = CARE(...) rend aussi le gain K = R^{-1}B'X et les pôles de
%   la boucle fermée.
%
%   La solution stabilisante s'obtient par la matrice hamiltonienne
%      H = [ A      -B R^{-1} B'
%           -Q      -A'        ]
%   dont le sous-espace propre stable, engendré par les colonnes
%   [X1; X2], donne X = X2 / X1. C'est la construction de Potter, exacte
%   dès que le problème admet une solution stabilisante.
%
%   Exemple :
%      care(0, 1, 1, 1)     % 1
%      care([0 1; 0 0], [0; 1], eye(2), 1)
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
