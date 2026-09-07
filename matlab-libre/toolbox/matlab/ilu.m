function [L, U, P] = ilu(A, options)
%ILU Factorisation LU incomplète.
%   [L,U] = ILU(A) rend deux matrices triangulaires dont le produit
%   approche A, en ne remplissant que les positions déjà non nulles de A.
%   [L,U,P] = ILU(A) rend en outre la permutation, ici l'identité :
%   l'option 'nofill' n'en emploie pas.
%   [...] = ILU(A,OPTIONS) accepte le champ 'type' ('nofill').
%
%   C'est le pendant non symétrique d'ICHOL, et il sert à la même chose :
%   préconditionner une méthode de Krylov. Sans remplissage, L et U ont
%   exactement le motif de A, donc le même coût mémoire — et c'est cela
%   qu'on achète en renonçant à l'exactitude.
%
%   La diagonale de L vaut un, celle de U porte les pivots. Un pivot nul
%   arrête la factorisation : sans permutation, rien ne peut le sauver, et
%   c'est la limite de la variante sans remplissage.
%
%   Exemple :
%      n = 20;
%      A = full(spdiags([-ones(n,1), 4*ones(n,1), -ones(n,1)], -1:1, n, n));
%      [L, U] = ilu(A);
%      istril(L) && istriu(U)                   % 1
%      max(max(abs(diag(L) - 1))) < 1e-12       % la diagonale de L vaut un
%      norm(A - L * U) < norm(A)                % l'approximation est proche
%
%   Voir aussi ICHOL, LU, GMRES, BICG, PCG.
    A = full(double(A));
    n = size(A, 1);
    if size(A, 2) ~= n
        error('MATLAB:ilu:NotSquare', 'La matrice doit être carrée.');
    end
    if nargin >= 2 && isstruct(options) && isfield(options, 'type') && ...
       ~strcmpi(char(options.type), 'nofill')
        error('MATLAB:ilu:UnsupportedType', ...
              'Seul le type « nofill » est traité.');
    end
    motif = A ~= 0;
    M = A;
    for k = 1:n-1
        if M(k, k) == 0
            error('MATLAB:ilu:ZeroPivot', ...
                  'Pivot nul en position %d : sans permutation, rien ne le sauve.', k);
        end
        for i = k+1:n
            if ~motif(i, k)
                continue
            end
            M(i, k) = M(i, k) / M(k, k);
            for j = k+1:n
                if motif(i, j)
                    M(i, j) = M(i, j) - M(i, k) * M(k, j);
                end
            end
        end
    end
    L = tril(M, -1) + eye(n);
    U = triu(M);
    P = eye(n);
end
