function [x, valeur] = bintprog(f, A, b)
%BINTPROG Programmation linéaire en variables binaires, par énumération.
%   X = BINTPROG(F,A,B) minimise f'*x sous A*x <= b, x dans {0,1}^n.
%   L'énumération est exhaustive : à réserver aux petits problèmes.
    f = f(:);
    n = numel(f);
    if n > 22
        error('optim:bintprog:TooLarge', ...
              'Exhaustive enumeration is limited to 22 variables.');
    end
    meilleur = [];
    valeur = inf;
    for code = 0:(2^n - 1)
        x = zeros(n, 1);
        reste = code;
        for k = 1:n
            x(k) = mod(reste, 2);
            reste = floor(reste / 2);
        end
        if ~isempty(A) && any(A * x > b(:) + 1e-9)
            continue;
        end
        v = f' * x;
        if v < valeur
            valeur = v;
            meilleur = x;
        end
    end
    x = meilleur;
end
