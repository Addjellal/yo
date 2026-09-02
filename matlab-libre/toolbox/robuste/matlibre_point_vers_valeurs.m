function valeurs = matlibre_point_vers_valeurs(noms, point)
%MATLIBRE_POINT_VERS_VALEURS Un vecteur de coordonnées, en structure nommée.
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
%   Le balayage travaille sur des vecteurs, l'évaluation sur des noms ;
%   cette fonction fait le passage.
    valeurs = struct();
    for k = 1:numel(noms)
        valeurs.(noms{k}) = point(k);
    end
end
