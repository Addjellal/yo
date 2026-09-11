function M = matlibre_symmat_etendre(arbre)
%MATLIBRE_SYMMAT_ETENDRE Développe une expression matricielle en matrice de SYM.
%   M = MATLIBRE_SYMMAT_ETENDRE(ARBRE) rend la matrice des éléments. Une
%   matrice nommée A de taille mxn donne les éléments A1_1 à Am_n ; les
%   opérations sont ensuite menées élément par élément, ou selon
%   l'algèbre matricielle pour le produit, l'inverse et le déterminant.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
%
%   Exemple :
%      M = matlibre_symmat_etendre({'mat', 'A', [1 2]});
%      char(M(1,2))                    % 'A1_2'
%
%   Voir aussi SYMMATRIX2SYM, SYMMATRIX.
    switch arbre{1}
        case 'mat'
            d = arbre{3};
            for i = 1:d(1)
                for j = 1:d(2)
                    M(i, j) = sym(sprintf('%s%d_%d', arbre{2}, i, j));   %#ok<AGROW>
                end
            end
        case 'const'
            valeurs = arbre{2};
            if isa(valeurs, 'sym')
                M = valeurs;
                return
            end
            for i = 1:size(valeurs, 1)
                for j = 1:size(valeurs, 2)
                    M(i, j) = sym(valeurs(i, j));   %#ok<AGROW>
                end
            end
        case {'+', '-', '.*', './'}
            M = elementParElement(arbre{1}, ...
                                  matlibre_symmat_etendre(arbre{2}), ...
                                  matlibre_symmat_etendre(arbre{3}));
        case '*'
            M = matlibre_symmat_produit(matlibre_symmat_etendre(arbre{2}), ...
                                        matlibre_symmat_etendre(arbre{3}));
        case 'trans'
            M = transpose(matlibre_symmat_etendre(arbre{2}));
        case 'neg'
            M = elementParElement('*', sym(-1), matlibre_symmat_etendre(arbre{2}));
        case 'inv'
            M = matlibre_symmat_inverse(matlibre_symmat_etendre(arbre{2}));
        case 'det'
            M = matlibre_symmat_determinant(matlibre_symmat_etendre(arbre{2}));
        case 'trace'
            A = matlibre_symmat_etendre(arbre{2});
            somme = A(1, 1);
            for k = 2:size(A, 1)
                somme = somme + A(k, k);
            end
            M = somme;
        case 'pow'
            A = matlibre_symmat_etendre(arbre{2});
            n = arbre{3};
            if n == 0
                M = identiteSym(size(A, 1));
                return
            end
            if n < 0
                A = matlibre_symmat_inverse(A);
                n = -n;
            end
            M = A;
            for k = 2:n
                M = matlibre_symmat_produit(M, A);
            end
        case 'kron'
            M = produitKronecker(matlibre_symmat_etendre(arbre{2}), ...
                                 matlibre_symmat_etendre(arbre{3}));
        otherwise
            error('symbolic:symmatrix:Operateur', ...
                  'Opérateur matriciel inconnu « %s ».', arbre{1});
    end
end

function M = elementParElement(operateur, A, B)
% Un opérande 1x1 se répand sur l'autre, comme partout ailleurs.
    [m, n] = plusGrand(size(A), size(B));
    for i = 1:m
        for j = 1:n
            a = prendre(A, i, j);
            b = prendre(B, i, j);
            switch operateur
                case '+',  M(i, j) = a + b;   %#ok<AGROW>
                case '-',  M(i, j) = a - b;   %#ok<AGROW>
                case '.*', M(i, j) = a * b;   %#ok<AGROW>
                case '*',  M(i, j) = a * b;   %#ok<AGROW>
                case './', M(i, j) = a / b;   %#ok<AGROW>
            end
        end
    end
end

function [m, n] = plusGrand(g, h)
    m = max(g(1), h(1));
    n = max(g(2), h(2));
end

function v = prendre(A, i, j)
    if numel(A) == 1
        v = A(1, 1);
    else
        v = A(i, j);
    end
end

function I = identiteSym(n)
    for i = 1:n
        for j = 1:n
            I(i, j) = sym(double(i == j));   %#ok<AGROW>
        end
    end
end

function K = produitKronecker(A, B)
    [ma, na] = size(A);
    [mb, nb] = size(B);
    for i = 1:ma
        for j = 1:na
            for p = 1:mb
                for q = 1:nb
                    K((i-1)*mb + p, (j-1)*nb + q) = A(i, j) * B(p, q);   %#ok<AGROW>
                end
            end
        end
    end
end
