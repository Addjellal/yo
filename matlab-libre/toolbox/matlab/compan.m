function A = compan(p)
%COMPAN Matrice compagnon d'un polynôme.
%   A = COMPAN(P) rend la matrice dont le polynôme caractéristique est P,
%   donné par ses coefficients du degré le plus haut au plus bas. Ses
%   valeurs propres sont donc les racines de P.
%
%   C'est ainsi que ROOTS trouve les racines : plutôt que de chercher les
%   zéros du polynôme, il calcule les valeurs propres de sa compagnon.
%   Le détour paraît absurde et ne l'est pas — les algorithmes de valeurs
%   propres sont bien plus stables que la recherche directe de racines,
%   qui perd toute précision dès que deux racines sont proches.
%
%   Le polynôme est normalisé par son coefficient de tête : un polynôme
%   dont ce coefficient est nul n'a pas de compagnon de cette taille.
%
%   Exemple :
%      p = poly([1 2 3]);              % (x-1)(x-2)(x-3)
%      compan(p)
%      sort(eig(compan(p)).')          % [1 2 3]
%
%   Voir aussi ROOTS, POLY, EIG, PASCAL.
    p = double(p(:)).';
    % Les zéros de tête ne comptent pas : ils abaissent le degré.
    premier = find(p ~= 0, 1);
    if isempty(premier)
        A = [];
        return
    end
    p = p(premier:end);
    n = numel(p) - 1;
    if n < 1
        A = [];
        return
    end
    A = zeros(n, n);
    A(1, :) = -p(2:end) / p(1);
    A(2:n, 1:n-1) = eye(n - 1);
end
