function n = vecnorm(A, p, dim)
%VECNORM Norme de chaque vecteur d'un tableau.
%   N = VECNORM(A) rend la norme 2 de chaque colonne.
%   N = VECNORM(A,P) utilise la norme P.
%   N = VECNORM(A,P,DIM) travaille le long de la dimension DIM.
    if nargin < 2 || isempty(p)
        p = 2;
    end
    if nargin < 3
        if isvector(A)
            dim = find(size(A) ~= 1, 1);
            if isempty(dim)
                dim = 1;
            end
        else
            dim = 1;
        end
    end
    if isinf(p)
        n = max(abs(A), [], dim);
    elseif p == 1
        n = sum(abs(A), dim);
    else
        n = sum(abs(A) .^ p, dim) .^ (1 / p);
    end
end
