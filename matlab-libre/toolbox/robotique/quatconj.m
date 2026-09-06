function q = quatconj(a)
%QUATCONJ Conjugué d'un quaternion.
%   Q = QUATCONJ(A) change le signe de la partie vectorielle.
%
%   Pour un quaternion unitaire — donc pour toute rotation — le conjugué
%   est l'inverse : c'est ce qui rend l'inversion d'une rotation gratuite,
%   là où l'inverse d'une matrice demanderait une transposition au mieux.
%
%   Sur un quaternion non unitaire, conjugué et inverse diffèrent : QUATINV
%   divise en plus par le carré de la norme.
%
%   Exemple :
%      q = rotm2quat(rotz(30));
%      quatmultiply(q, quatconj(q))    % [1 0 0 0]
%      quatconj(q) - quatinv(q)        % ~0 : q est unitaire
%
%   Voir aussi QUATINV, QUATNORMALIZE, QUATMULTIPLY.
    q = [a(1), -a(2), -a(3), -a(4)];
end
