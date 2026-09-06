function P = pascal(n, genre)
%PASCAL Matrice de Pascal.
%   P = PASCAL(N) rend la matrice symétrique définie positive dont les
%   termes sont les coefficients binomiaux : P(i,j) = C(i+j-2, i-1).
%   Sa première ligne et sa première colonne ne comptent que des uns, et
%   chaque autre terme est la somme de celui du dessus et de celui de
%   gauche.
%   P = PASCAL(N,1) rend le facteur triangulaire inférieur, qui est sa
%   propre inverse au signe près.
%   P = PASCAL(N,2) rend une rotation de ce facteur, dont le cube vaut
%   l'identité.
%
%   Son déterminant vaut un, quelle que soit sa taille : c'est ce qui en
%   fait un cas d'école du mauvais conditionnement, car ses valeurs
%   propres s'écartent énormément tout en gardant un produit égal à un.
%   Elle sert à éprouver un solveur linéaire.
%
%   Exemple :
%      pascal(4)
%      det(pascal(6))                  % 1, malgre des termes jusqu'a 252
%      cond(pascal(6))                 % enorme : mal conditionnee
%      L = pascal(4, 1);
%      L * L                           % l'identite : L est son inverse
%
%   Voir aussi HADAMARD, MAGIC, HILB, TOEPLITZ.
    if nargin < 2
        genre = 0;
    end
    n = double(n);
    % Le facteur triangulaire signé : L(i,j) = (-1)^(j-1) C(i-1, j-1).
    % C'est le signe alterné qui en fait une involution, L L = I.
    L = zeros(n, n);
    for i = 1:n
        for j = 1:i
            L(i, j) = (-1) ^ (j - 1) * nchoosek(i - 1, j - 1);
        end
    end
    switch genre
        case 1
            P = L;
        case 2
            % Un quart de tour dans le sens direct, changé de signe pour
            % les tailles paires : la matrice obtenue vérifie P^3 = I.
            P = rot90(L, 3);
            if mod(n, 2) == 0
                P = -P;
            end
        otherwise
            % La symétrique : chaque terme est la somme de celui du dessus
            % et de celui de gauche, et son déterminant vaut un.
            P = zeros(n, n);
            for i = 1:n
                P(i, 1) = 1;
                P(1, i) = 1;
            end
            for i = 2:n
                for j = 2:n
                    P(i, j) = P(i-1, j) + P(i, j-1);
                end
            end
    end
end
