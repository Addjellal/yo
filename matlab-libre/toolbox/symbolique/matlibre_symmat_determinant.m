function d = matlibre_symmat_determinant(A)
%MATLIBRE_SYMMAT_DETERMINANT Déterminant symbolique par les cofacteurs.
%   D = MATLIBRE_SYMMAT_DETERMINANT(A) développe le long de la première
%   ligne. L'élimination de Gauss serait moins coûteuse mais demanderait
%   de diviser par des expressions dont on ne sait pas si elles
%   s'annulent ; les cofacteurs n'ont pas ce défaut.
%
%   Le nombre de termes croît comme n! : c'est une méthode pour petites
%   matrices, et c'en est aussi la seule honnête sans hypothèse sur les
%   éléments.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
%
%   Exemple :
%      A = [sym('a') sym('b'); sym('c') sym('d')];
%      char(matlibre_symmat_determinant(A))    % 'a*d - b*c'
%
%   Voir aussi SYMMATRIX, DET, MATLIBRE_SYMMAT_INVERSE.
    n = size(A, 1);
    if n == 1
        d = A(1, 1);
        return
    end
    if n == 2
        d = A(1, 1) * A(2, 2) - A(1, 2) * A(2, 1);
        return
    end
    d = sym(0);
    for j = 1:n
        mineur = A(2:n, [1:j-1, j+1:n]);
        terme = A(1, j) * matlibre_symmat_determinant(mineur);
        if mod(j, 2) == 0
            d = d - terme;
        else
            d = d + terme;
        end
    end
end
