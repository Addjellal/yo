function [n, iterations] = normest(A, tolerance)
%NORMEST Estime la norme spectrale par la méthode de la puissance.
%   N = NORMEST(A) estime la plus grande valeur singulière de A à 1e-6
%   près. N = NORMEST(A,TOL) impose la tolérance relative.
%   [N,K] = NORMEST(...) rend en outre le nombre d'itérations.
%
%   L'itération est celle de la puissance appliquée à A'*A : partant d'un
%   vecteur quelconque, on alterne x <- A*x et x <- A'*x en normalisant, et
%   la norme du résultat converge vers la plus grande valeur singulière.
%   La convergence est géométrique, de raison le carré du rapport entre la
%   deuxième et la première valeur singulière : rapide quand la première
%   domine, lente quand deux sont proches.
%
%   Elle ne demande que des produits matrice-vecteur, jamais la matrice
%   entière : c'est ce qui la rend utilisable sur une grande matrice
%   creuse, là où SVD demanderait de la remplir.
%
%   Le résultat est une estimation par le bas — l'itération monte vers la
%   vraie valeur sans jamais la dépasser.
%
%   Exemple :
%      A = magic(5);
%      abs(normest(A) - norm(A)) / norm(A) < 1e-6
%      normest(eye(4))                    % 1
%
%   Voir aussi NORM, COND, CONDEST, SVD.
    if nargin < 2 || isempty(tolerance)
        tolerance = 1e-6;
    end
    A = double(A);
    if isempty(A)
        n = 0;
        iterations = 0;
        return
    end
    % Un vecteur de uns plutôt qu'un tirage : le résultat est alors
    % reproductible, et le cas pathologique — un vecteur orthogonal au
    % premier singulier — est écarté par le repli sur une colonne.
    x = ones(size(A, 2), 1);
    if norm(A * x) == 0
        [~, colonne] = max(sum(abs(A), 1));
        x = zeros(size(A, 2), 1);
        x(colonne) = 1;
    end
    n = norm(x);
    x = x / n;
    n = 0;
    iterations = 0;
    for k = 1:1000
        iterations = k;
        precedent = n;
        y = A * x;
        n = norm(y);
        if n == 0
            return
        end
        x = A' * y;
        normeX = norm(x);
        if normeX == 0
            return
        end
        x = x / normeX;
        if abs(n - precedent) <= tolerance * n
            return
        end
    end
end
