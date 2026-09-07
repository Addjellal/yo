function b = pagectranspose(a)
%PAGECTRANSPOSE Transposée conjuguée de chaque page d'un tableau.
%   B = PAGECTRANSPOSE(A) échange les deux premières dimensions de A et
%   conjugue les valeurs.
%
%   Exemple :
%      a = cat(3, [1 1i; 0 1], [1 0; 0 1]);
%      b = pagectranspose(a);
%      b(1, 2, 1)                  % 0 : la transposition conjugue aussi
%
%   Voir aussi PAGETRANSPOSE, PAGEMTIMES.
    b = conj(pagetranspose(a));
end
