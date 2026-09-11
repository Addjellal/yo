function Z = matlibre_evaluer_grille3(fonction, X, Y, z)
%MATLIBRE_EVALUER_GRILLE3 Évalue une poignée de trois variables sur une tranche.
%   La troisième coordonnée est fixée : on obtient la coupe de la
%   fonction à cette altitude, dont la ligne de niveau zéro est la trace
%   de la surface implicite.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
%
%   Exemple :
%      [X, Y] = meshgrid(-1:1, -1:1);
%      Z = matlibre_evaluer_grille3(@(x,y,z) x + y + z, X, Y, 1);
%      Z(2, 2)                         % 1 : au centre, x et y sont nuls
%
%   Voir aussi FIMPLICIT3, MATLIBRE_EVALUER_GRILLE.
    Z = [];
    try
        Z = fonction(X, Y, z * ones(size(X)));
    catch
        Z = [];
    end
    if ~isequal(size(Z), size(X))
        Z = zeros(size(X));
        for k = 1:numel(X)
            Z(k) = double(fonction(X(k), Y(k), z));
        end
    end
    Z = double(Z);
end
