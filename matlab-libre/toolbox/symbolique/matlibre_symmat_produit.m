function C = matlibre_symmat_produit(A, B)
%MATLIBRE_SYMMAT_PRODUIT Produit de deux matrices de SYM.
%   C = MATLIBRE_SYMMAT_PRODUIT(A,B) rend le produit matriciel, terme à
%   terme : C(i,j) est la somme des A(i,k)*B(k,j). Un opérande 1x1 est
%   traité comme un facteur d'échelle.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
%
%   Exemple :
%      A = [sym('a') sym('b')];
%      B = [sym('c'); sym('d')];
%      char(matlibre_symmat_produit(A, B))     % 'a*c + b*d'
%
%   Voir aussi SYMMATRIX, MATLIBRE_SYMMAT_ETENDRE.
    if numel(A) == 1 || numel(B) == 1
        if numel(A) == 1
            facteur = A(1, 1);
            M = B;
        else
            facteur = B(1, 1);
            M = A;
        end
        for i = 1:size(M, 1)
            for j = 1:size(M, 2)
                C(i, j) = facteur * M(i, j);   %#ok<AGROW>
            end
        end
        return
    end
    [m, k] = size(A);
    n = size(B, 2);
    for i = 1:m
        for j = 1:n
            somme = A(i, 1) * B(1, j);
            for p = 2:k
                somme = somme + A(i, p) * B(p, j);
            end
            C(i, j) = somme;   %#ok<AGROW>
        end
    end
end
