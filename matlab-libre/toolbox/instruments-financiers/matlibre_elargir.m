function M = matlibre_elargir(M, largeur)
%MATLIBRE_ELARGIR Complète une matrice à droite par des NaN.
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
    if size(M, 2) < largeur
        M = [M, nan(size(M, 1), largeur - size(M, 2))];
    end
end
