function n = quatconj(q)
%QUATCONJ Conjugué de quaternions [w x y z], ligne par ligne.
%   N = QUATCONJ(Q) change le signe de la partie vectorielle de chaque
%   ligne de Q (M x 4).
%
%   Pour un quaternion unitaire — donc pour toute rotation — le conjugué
%   est l'inverse : c'est ce qui rend l'inversion d'une rotation gratuite,
%   là où l'inverse d'une matrice demanderait une transposition au mieux.
%
%   Sur un quaternion non unitaire, conjugué et inverse diffèrent : QUATINV
%   divise en plus par le carré de la norme.
%
%   Exemple :
%      quatconj([1 0 1 0])             % [1 0 -1 0], documentation de MATLAB
%      q = rotm2quat(rotz(30));
%      quatmultiply(q, quatconj(q))    % [1 0 0 0]
%      quatconj(q) - quatinv(q)        % ~0 : q est unitaire
%
%   Voir aussi QUATINV, QUATNORMALIZE, QUATMULTIPLY.
    if size(q, 2) ~= 4
        error('aero:quatconj:Taille', 'Les quaternions sont des lignes [w x y z] : M x 4.');
    end
    n = [q(:, 1), -q(:, 2:4)];
end
