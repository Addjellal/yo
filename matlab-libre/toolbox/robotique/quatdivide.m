function n = quatdivide(q, r)
%QUATDIVIDE Division de quaternions, comme MATLAB : inv(R) x Q.
%   N = QUATDIVIDE(Q,R) rend, ligne par ligne, le produit de l'inverse de
%   R par Q, quatmultiply(quatinv(R), Q) :
%      n0 = (r0 q0 + r1 q1 + r2 q2 + r3 q3) / |r|^2
%      n1 = (r0 q1 - r1 q0 - r2 q3 + r3 q2) / |r|^2
%      n2 = (r0 q2 + r1 q3 - r2 q0 - r3 q1) / |r|^2
%      n3 = (r0 q3 - r1 q2 + r2 q1 - r3 q0) / |r|^2
%   Q et R sont M x 4, ou l'un des deux 1 x 4.
%
%   La multiplication des quaternions n'est pas commutative : diviser à
%   gauche et diviser à droite ne donnent pas le même résultat. MATLAB
%   divise à gauche, si bien que quatmultiply(R, quatdivide(Q,R)) redonne
%   Q ; quatmultiply(quatdivide(Q,R), R) ne le redonne pas en général.
%
%   Exemple :
%      % Documentation de MATLAB : [0.7273 0.1212 0.2424 -0.6061].
%      quatdivide([1 0 1 0], [1 0.5 0.5 0.75])
%      q = eul2quat([0.3 0.2 0.1]);
%      quatdivide(q, q)                % [1 0 0 0]
%
%   Voir aussi QUATMULTIPLY, QUATINV, QUATCONJ.
    [q, r] = matlibre_quat_paire(double(q), double(r), 'quatdivide');
    n = quatmultiply(quatinv(r), q);
end
