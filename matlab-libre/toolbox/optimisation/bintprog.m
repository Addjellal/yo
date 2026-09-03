function [x, valeur] = bintprog(f, A, b)
%BINTPROG Programmation linéaire en variables binaires, par énumération.
%   X = BINTPROG(F,A,B) minimise f'*x sous A*x <= b, x dans {0,1}^n.
%   L'énumération est exhaustive : à réserver aux petits problèmes.
%   Vingt-deux variables au plus — au-delà, l'appel est refusé plutôt
%   que laissé tourner ; INTLINPROG, qui coupe l'arbre, prend le relais.
%
%   [X,VAL] = BINTPROG(...) rend aussi la valeur atteinte.
%
%   Exemple :
%      % Un sac à dos : deux objets de valeurs 1 et 2, une seule place.
%      [x, val] = bintprog([-1; -2], [1 1], 1);
%      x                              % [0; 1] : on prend le meilleur
%      val                            % -2
%
%   Voir aussi INTLINPROG, LINPROG, QUADPROG, OPTIMPROBLEM.
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
