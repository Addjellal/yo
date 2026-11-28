function n = quatnormalize(q)
%QUATNORMALIZE Quaternions unitaires, ligne par ligne.
%   N = QUATNORMALIZE(Q) divise chaque ligne de Q (M x 4) par sa norme,
%   racine de q0^2 + q1^2 + q2^2 + q3^2.
%
%   Seuls les quaternions unitaires représentent des rotations. Une longue
%   suite de produits fait lentement dériver la norme par accumulation
%   d'erreurs d'arrondi : renormaliser de temps en temps est le remède, et
%   il est bien moins coûteux que la réorthogonalisation d'une matrice.
%
%   Exemple :
%      quatnormalize([1 0 1 0])        % [0.7071 0 0.7071 0], documentation de MATLAB
%      quatnormalize([2 0 0 0; 0 0 3 4])
%
%   Voir aussi QUATMOD, QUATNORM, QUATCONJ, QUATINV, QUATMULTIPLY.
    if size(q, 2) ~= 4
        error('aero:quatnormalize:Taille', 'Quaternions must be rows [w x y z]: M-by-4.');
    end
    n = q ./ quatmod(q);
end
