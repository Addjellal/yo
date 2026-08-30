function R = matlibre_racine_carree(M)
%MATLIBRE_RACINE_CARREE Racine carrée d'une matrice symétrique positive.
%   R = MATLIBRE_RACINE_CARREE(M) rend la matrice symétrique R telle que
%   R*R = M, pour M symétrique définie positive. Elle passe par la
%   décomposition en valeurs propres : M = V*D*V', donc R = V*sqrt(D)*V'.
%
%   C'est ce dont le décalage de boucle de la synthèse H-infini a besoin,
%   là où SQRTM, qui traite le cas général, coûterait davantage.
%
%   Cette fonction est un utilitaire interne de la boîte à outils
%   Automatique : elle n'existe pas dans MATLAB.
%
%   Voir aussi SQRTM, CHOL, EIG.
    M = (M + M') / 2;
    [V, D] = eig(M);
    valeurs = real(diag(D));
    valeurs(valeurs < 0) = 0;
    R = real(V * diag(sqrt(valeurs)) * V');
    R = (R + R') / 2;
end
