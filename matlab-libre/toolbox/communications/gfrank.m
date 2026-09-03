function r = gfrank(A, p)
%GFRANK Rang d'une matrice sur un corps de Galois.
%   R = GFRANK(A,P) rend le rang de A sur GF(P), P premier, par
%   élimination de Gauss avec pivots dans le corps.
%   R = GFRANK(A) le fait sur GF(2).
%
%   Le rang d'un corps fini n'est pas celui des réels : une matrice
%   inversible sur les réels peut être singulière modulo P, et
%   réciproquement.
%
%   Exemple :
%      gfrank([1 1; 1 1])             % 1
%      gfrank([1 0; 0 1])             % 2
%      gfrank([2 4; 1 2], 5)          % 1 : la seconde ligne est la
%                                     % première divisée par deux
%
%   Voir aussi GFDIV, GFADD, GFWEIGHT, RANK.
    if nargin < 2 || isempty(p), p = 2; end
    exigerPremier(p, 'gfrank');
    A = mod(double(A), p);
    [lignes, colonnes] = size(A);
    r = 0;
    ligneCourante = 1;
    for colonne = 1:colonnes
        if ligneCourante > lignes
            break
        end
        pivot = find(A(ligneCourante:lignes, colonne) ~= 0, 1);
        if isempty(pivot)
            continue
        end
        pivot = pivot + ligneCourante - 1;
        echange = A(ligneCourante, :);
        A(ligneCourante, :) = A(pivot, :);
        A(pivot, :) = echange;
        inverse = gfdiv(1, A(ligneCourante, colonne), p);
        A(ligneCourante, :) = mod(A(ligneCourante, :) * inverse, p);
        for k = 1:lignes
            if k ~= ligneCourante && A(k, colonne) ~= 0
                A(k, :) = mod(A(k, :) - A(k, colonne) * A(ligneCourante, :), p);
            end
        end
        ligneCourante = ligneCourante + 1;
        r = r + 1;
    end
end
