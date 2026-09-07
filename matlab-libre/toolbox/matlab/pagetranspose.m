function b = pagetranspose(a)
%PAGETRANSPOSE Transposée de chaque page d'un tableau.
%   B = PAGETRANSPOSE(A) échange les deux premières dimensions de A, les
%   suivantes restant en place.
%
%   Exemple :
%      a = cat(3, [1 2; 3 4], [5 6; 7 8]);
%      b = pagetranspose(a);
%      b(:, :, 1)                  % [1 3; 2 4]
%
%   Voir aussi PAGECTRANSPOSE, PAGEMTIMES, PERMUTE.
    d = max(ndims(a), 2);
    b = permute(a, [2, 1, 3:d]);
end
