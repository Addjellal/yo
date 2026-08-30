function R = lyapchol(A, B)
%LYAPCHOL Facteur de Cholesky de la solution de Lyapunov.
%   R = LYAPCHOL(A,B) rend la matrice triangulaire supérieure R telle que
%   X = R'*R résolve A*X + X*A' + B*B' = 0. Travailler sur R plutôt que
%   sur X garde la positivité exacte et double la précision : c'est ce
%   qu'emploient les réductions de modèle.
%
%   A doit être stable.
%
%   Exemples :
%      R = lyapchol(-1, 1);
%      abs(R' * R - 0.5) < 1e-12        % X = 0.5 pour ce cas
%      X = lyapchol([-1 0; 0 -2], eye(2))' * lyapchol([-1 0; 0 -2], eye(2));
%      max(max(abs([-1 0; 0 -2] * X + X * [-1 0; 0 -2]' + eye(2)))) < 1e-12
%
%   Voir aussi LYAP, DLYAP, GRAM, BALREAL, CHOL.
    X = lyap(A, B * B');
    X = (X + X') / 2;
    % Les valeurs propres légèrement négatives viennent de l'arrondi : on
    % les ramène à zéro avant la factorisation.
    [V, D] = eig(X);
    valeurs = real(diag(D));
    valeurs(valeurs < 0) = 0;
    racine = V * diag(sqrt(valeurs)) * V';
    R = triu(qr(real(racine)));
    % Le signe des lignes est arbitraire ; on le fixe pour que la
    % diagonale soit positive, comme le fait CHOL.
    for k = 1:size(R, 1)
        if R(k, k) < 0
            R(k, :) = -R(k, :);
        end
    end
end
