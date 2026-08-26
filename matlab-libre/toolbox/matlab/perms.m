function P = perms(v)
%PERMS Toutes les permutations des éléments d'un vecteur.
%   P = PERMS(V) rend une matrice dont chaque ligne est une permutation
%   de V. L'ordre suit celui de MATLAB : lexicographique inverse.
    v = v(:).';
    n = numel(v);
    if n == 0
        P = [];
        return;
    end
    if n == 1
        P = v;
        return;
    end
    P = [];
    for k = n:-1:1
        reste = v([1:k-1, k+1:n]);
        sous = perms(reste);
        P = [P; repmat(v(k), size(sous,1), 1), sous];
    end
end
