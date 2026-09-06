function q = quatnormalize(a)
%QUATNORMALIZE Quaternion unitaire.
%   Q = QUATNORMALIZE(A) divise par la norme.
%
%   Seuls les quaternions unitaires représentent des rotations. Une longue
%   suite de produits fait lentement dériver la norme par accumulation
%   d'erreurs d'arrondi : renormaliser de temps en temps est le remède, et
%   il est bien moins coûteux que la réorthogonalisation d'une matrice.
%
%   Exemple :
%      norm(quatnormalize([2 0 0 0]))  % 1
%      quatnormalize([2 0 0 0])        % [1 0 0 0]
%
%   Voir aussi QUATCONJ, QUATINV, QUATMULTIPLY.
    q = a / norm(a);
end
