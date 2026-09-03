function b = pagectranspose(a)
%PAGECTRANSPOSE Transposée conjuguée de chaque page d'un tableau.
%   B = PAGECTRANSPOSE(A) échange les deux premières dimensions de A et
%   conjugue les valeurs.
%
%   Voir aussi PAGETRANSPOSE, PAGEMTIMES.
    b = conj(pagetranspose(a));
end
