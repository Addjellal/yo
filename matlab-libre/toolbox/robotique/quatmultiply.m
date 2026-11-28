function n = quatmultiply(q, r)
%QUATMULTIPLY Produit de quaternions [w x y z], ligne par ligne.
%   N = QUATMULTIPLY(Q,R) rend le produit de Hamilton Q x R de chaque ligne
%   de Q par la ligne correspondante de R ; Q et R sont M x 4, ou l'un des
%   deux 1 x 4. N = QUATMULTIPLY(Q) rend Q x Q. Comme MATLAB :
%      n0 = r0 q0 - r1 q1 - r2 q2 - r3 q3
%      n1 = r0 q1 + r1 q0 - r2 q3 + r3 q2
%      n2 = r0 q2 + r1 q3 + r2 q0 - r3 q1
%      n3 = r0 q3 - r1 q2 + r2 q1 + r3 q0
%   Pour des quaternions unitaires, le produit compose les rotations :
%   quat2rotm(Q x R) = quat2rotm(Q) * quat2rotm(R).
%
%   C'est ce qui fait l'intérêt des quaternions : composer deux rotations
%   coûte seize multiplications au lieu de vingt-sept, et le résultat
%   reste unitaire à la précision machine — là où un produit de matrices
%   dérive lentement de l'orthogonalité et demande une réorthogonalisation.
%
%   Le produit n'est pas commutatif, pas plus que celui des rotations.
%
%   Exemple :
%      % Documentation de MATLAB : [0.5 1.25 1.5 0.25] et [1.9 1.1 2.1 -0.9].
%      quatmultiply([1 0 1 0], [1 0.5 0.5 0.75; 2 1 0.1 0.1])
%      quatmultiply([1 0 1 0])         % [0 0 2 0]
%
%   Voir aussi QUATDIVIDE, QUATCONJ, QUATINV, QUAT2ROTM.
    if nargin < 2
        r = q;
    end
    [q, r] = matlibre_quat_paire(double(q), double(r), 'quatmultiply');
    n = [r(:, 1) .* q(:, 1) - r(:, 2) .* q(:, 2) - r(:, 3) .* q(:, 3) - r(:, 4) .* q(:, 4), ...
         r(:, 1) .* q(:, 2) + r(:, 2) .* q(:, 1) - r(:, 3) .* q(:, 4) + r(:, 4) .* q(:, 3), ...
         r(:, 1) .* q(:, 3) + r(:, 2) .* q(:, 4) + r(:, 3) .* q(:, 1) - r(:, 4) .* q(:, 2), ...
         r(:, 1) .* q(:, 4) - r(:, 2) .* q(:, 3) + r(:, 3) .* q(:, 2) + r(:, 4) .* q(:, 1)];
end
