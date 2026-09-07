function x = lsqminnorm(A, B, tolerance)
%LSQMINNORM Solution de moindre norme au sens des moindres carrés.
%   X = LSQMINNORM(A,B) rend, parmi toutes les solutions qui minimisent
%   NORM(A*X-B), celle de plus petite norme. X = LSQMINNORM(A,B,TOL)
%   impose le seuil sous lequel une valeur singulière est tenue pour nulle.
%
%   Quand A est de rang plein en colonnes, il n'y a qu'une solution et
%   LSQMINNORM rend la même chose que l'antislash. La différence apparaît
%   quand A est déficiente : l'antislash rend alors une solution à
%   coefficients épars, obtenue par la décomposition QR, tandis que
%   LSQMINNORM rend celle de norme minimale, qui est unique. La première
%   met des zéros là où la seconde répartit.
%
%   Aucune des deux n'est meilleure en soi. La solution de moindre norme
%   est la seule continue en A : une perturbation infime des données ne la
%   déplace que d'autant, alors qu'elle peut faire sauter la solution
%   éparse d'un jeu de colonnes à un autre.
%
%   Le seuil par défaut est max(size(A))*eps(norm(A)) : c'est celui qui
%   sépare les valeurs singulières nulles de celles que l'arrondi a
%   simplement rendues petites.
%
%   Exemple :
%      A = [1 1; 1 1];
%      b = [2; 2];
%      x = lsqminnorm(A, b);              % [1; 1], de norme minimale
%      norm(A * x - b) < 1e-12
%      norm(x) <= norm(A \ b) + 1e-12     % jamais plus grande
%
%   Voir aussi PINV, MLDIVIDE, RANK, SVD.
    A = double(A);
    B = double(B);
    [U, S, V] = svd(A, 'econ');
    s = diag(S);
    if nargin < 3 || isempty(tolerance)
        if isempty(s)
            tolerance = 0;
        else
            tolerance = max(size(A)) * eps(max(s));
        end
    end
    garde = s > tolerance;
    if ~any(garde)
        x = zeros(size(A, 2), size(B, 2));
        return
    end
    % La solution de moindre norme s'écrit dans la base des vecteurs
    % singuliers : on annule ce que les valeurs nulles ne déterminent pas.
    x = V(:, garde) * ((U(:, garde)' * B) ./ s(garde));
end
