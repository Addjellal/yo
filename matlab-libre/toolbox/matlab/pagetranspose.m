function b = pagetranspose(a)
%PAGETRANSPOSE Transposée de chaque page d'un tableau.
%   B = PAGETRANSPOSE(A) échange les deux premières dimensions de A, les
%   suivantes restant en place.
%
%   Voir aussi PAGECTRANSPOSE, PAGEMTIMES, PERMUTE.
    d = max(ndims(a), 2);
    b = permute(a, [2, 1, 3:d]);
end
