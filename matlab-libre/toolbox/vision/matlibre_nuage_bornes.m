function bornes = matlibre_nuage_bornes(nuage, axe)
%MATLIBRE_NUAGE_BORNES Étendue d'un nuage selon un axe.
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
    points = matlibre_nuage_points(nuage);
    if isempty(points)
        bornes = [];
        return
    end
    colonne = points(:, axe);
    valides = colonne(isfinite(colonne));
    bornes = [min(valides), max(valides)];
end
