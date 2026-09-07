function [n, v, w, iterations] = normest1(A, t)
%NORMEST1 Estime la norme 1 par l'algorithme de Hager.
%   N = NORMEST1(A) estime la plus grande somme des modules d'une colonne.
%   [N,V,W] = NORMEST1(A) rend en outre un vecteur V tel que W = A*V et
%   NORM(W,1) = N*NORM(V,1) : le témoin de l'estimation.
%   [N,V,W,K] = NORMEST1(...) rend le nombre d'itérations.
%
%   La norme 1 d'une matrice est le maximum de ||A*x||_1 sur les x de norme
%   1. Ce maximum est atteint en un sommet du cube unité — un vecteur de
%   plus ou moins un — et l'algorithme de Hager cherche ce sommet en
%   suivant le gradient du signe : partant de x, on calcule A*x, on prend
%   son signe, on calcule A'*signe, et l'on saute au sommet indiqué par sa
%   plus grande composante.
%
%   L'estimation est toujours une borne inférieure, et elle est presque
%   toujours exacte. Elle ne demande que des produits par A et par A',
%   ce qui la rend applicable là où l'on ne veut pas parcourir toutes les
%   colonnes.
%
%   Exemple :
%      A = magic(5);
%      normest1(A) == norm(A, 1)          % 1 : exacte ici
%      [n, v, w] = normest1(magic(4));
%      abs(norm(w, 1) - n * norm(v, 1)) < 1e-10
%
%   Voir aussi NORM, NORMEST, CONDEST.
    if nargin < 2 || isempty(t)
        t = 2;   %#ok<NASGU>  le nombre de colonnes d'essai, sans effet ici
    end
    A = double(A);
    m = size(A, 2);
    if isempty(A)
        n = 0; v = []; w = []; iterations = 0;
        return
    end
    v = ones(m, 1) / m;
    n = 0;
    iterations = 0;
    vus = false(m, 1);
    for k = 1:min(5 * m + 5, 200)
        iterations = k;
        w = A * v;
        n = norm(w, 1);
        signes = sign(w);
        signes(signes == 0) = 1;
        z = A' * signes;
        [maximum, j] = max(abs(z));
        if maximum <= z' * v || vus(j)
            return
        end
        vus(j) = true;
        v = zeros(m, 1);
        v(j) = 1;
    end
end
