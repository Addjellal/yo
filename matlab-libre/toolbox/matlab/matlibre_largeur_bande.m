function b = matlibre_largeur_bande(A)
%MATLIBRE_LARGEUR_BANDE Distance maximale d'un coefficient non nul à la diagonale.
%   C'est la quantité que SYMRCM cherche à réduire : la factorisation
%   d'une matrice de bande B coûte O(N*B^2) et n'en sort jamais.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
%
%   Exemple :
%      matlibre_largeur_bande(eye(4))       % 0
%      matlibre_largeur_bande(ones(4))      % 3
%
%   Voir aussi SYMRCM, SYMAMD, BANDWIDTH.
    [i, j] = find(A ~= 0);
    if isempty(i)
        b = 0;
    else
        b = max(abs(i - j));
    end
end
