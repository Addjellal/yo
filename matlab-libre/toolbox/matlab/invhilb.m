function H = invhilb(n)
%INVHILB Inverse exacte de la matrice de Hilbert.
%   H = INVHILB(N) rend l'inverse de HILB(N), calculée par sa formule
%   fermée en coefficients binomiaux plutôt que par inversion numérique.
%
%   La matrice de Hilbert est le cas d'école du mauvais
%   conditionnement : son nombre de conditionnement croît comme e^(3,5 N),
%   si bien qu'à N = 13 l'inversion numérique n'a plus un seul chiffre
%   juste. La formule fermée, elle, reste exacte tant que les entiers
%   qu'elle produit tiennent dans un double — jusqu'à N = 13 environ.
%
%   Tous ses termes sont des entiers, alternés en signe. C'est ce qui
%   permet de mesurer l'erreur d'un solveur : la vraie réponse est connue.
%
%   Exemple :
%      norm(invhilb(6) * hilb(6) - eye(6))     % petit
%      max(max(abs(invhilb(5) - round(invhilb(5)))))   % 0 : des entiers
%      cond(hilb(12))                          % plus de 1e16
%
%   Voir aussi HILB, PASCAL, COND.
    n = double(n);
    H = zeros(n, n);
    for i = 1:n
        for j = 1:n
            H(i, j) = (-1) ^ (i + j) * (i + j - 1) * ...
                      nchoosek(n + i - 1, n - j) * ...
                      nchoosek(n + j - 1, n - i) * ...
                      nchoosek(i + j - 2, i - 1) ^ 2;
        end
    end
end
