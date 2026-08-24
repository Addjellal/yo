function verifierPermutation(permutation)
%VERIFIERPERMUTATION Contrôle qu'un vecteur est bien une permutation.
    n = numel(permutation);
    if ~isequal(sort(permutation(:))', 1:n)
        error('comm:intrlv:BadPermutation', ...
              'Le vecteur doit être une permutation de 1 à %d.', n);
    end
end
