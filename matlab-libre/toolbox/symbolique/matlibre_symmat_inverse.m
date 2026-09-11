function R = matlibre_symmat_inverse(A)
%MATLIBRE_SYMMAT_INVERSE Inverse symbolique par la comatrice.
%   R = MATLIBRE_SYMMAT_INVERSE(A) rend la transposée de la comatrice
%   divisée par le déterminant. Chaque élément est donc un quotient de
%   déterminants, sans qu'aucun pivot n'ait été supposé non nul : c'est
%   ce qui permet d'inverser une matrice dont on ne connaît pas les
%   valeurs.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
%
%   Exemple :
%      A = [sym('a') sym('b'); sym('c') sym('d')];
%      R = matlibre_symmat_inverse(A);
%      char(R(1, 1))                   % 'd/(a*d - b*c)'
%
%   Voir aussi SYMMATRIX, INV, MATLIBRE_SYMMAT_DETERMINANT.
    n = size(A, 1);
    d = matlibre_symmat_determinant(A);
    if n == 1
        R(1, 1) = sym(1) / A(1, 1);
        return
    end
    for i = 1:n
        for j = 1:n
            mineur = A([1:i-1, i+1:n], [1:j-1, j+1:n]);
            cofacteur = matlibre_symmat_determinant(mineur);
            if mod(i + j, 2) == 1
                cofacteur = -cofacteur;
            end
            % La comatrice se transpose : l'inverse est adj(A)'/det(A).
            R(j, i) = cofacteur / d;   %#ok<AGROW>
        end
    end
end
