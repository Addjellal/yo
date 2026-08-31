function M = symdec(taille, decalage)
%SYMDEC Matrice symétrique de repères.
%   M = SYMDEC(N,K) rend la matrice N x N symétrique dont chaque entrée
%   du triangle inférieur porte un numéro consécutif à partir de K+1, la
%   diagonale comprise.
%
%   Comme SKEWDEC, c'est un gabarit de repères et non une matrice de
%   calcul : il numérote les N(N+1)/2 inconnues d'une variable symétrique.
%
%   Exemples :
%      symdec(3, 0)
%      % [ 1  2  4
%      %   2  3  5
%      %   4  5  6 ]
%
%   Voir aussi SKEWDEC, DIAG, TRIL, TRIU.
    if nargin < 2 || isempty(decalage)
        decalage = 0;
    end
    n = round(taille);
    M = zeros(n, n);
    numero = decalage;
    for j = 1:n
        for i = j:n
            numero = numero + 1;
            M(i, j) = numero;
            M(j, i) = numero;
        end
    end
end
