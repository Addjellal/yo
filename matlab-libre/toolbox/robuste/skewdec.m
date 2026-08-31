function M = skewdec(taille, decalage)
%SKEWDEC Matrice antisymétrique de repères.
%   M = SKEWDEC(N,K) rend la matrice N x N antisymétrique dont l'élément
%   (I,J), pour I supérieur à J, vaut -(K + J + (I-1)*(I-2)/2) et dont la
%   diagonale est nulle.
%
%   Ce n'est pas une matrice de calcul : c'est un gabarit de repères. Les
%   fonctions d'inégalités matricielles s'en servent pour numéroter les
%   inconnues d'une variable antisymétrique, chaque entrée portant le
%   numéro de la variable scalaire qui la remplira.
%
%   Exemples :
%      skewdec(3, 0)
%      % [   0  -1  -2
%      %     1   0  -3
%      %     2   3   0 ]
%
%      skewdec(2, 10)
%
%   Voir aussi SYMDEC, DIAG, TRIL, TRIU.
    if nargin < 2 || isempty(decalage)
        decalage = 0;
    end
    n = round(taille);
    M = zeros(n, n);
    for i = 2:n
        for j = 1:i - 1
            numero = decalage + j + (i - 1) * (i - 2) / 2;
            M(i, j) = numero;
            M(j, i) = -numero;
        end
    end
end
