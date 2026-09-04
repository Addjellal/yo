function nuage = matlibre_nuage_grille(modele, points, pas)
%MATLIBRE_NUAGE_GRILLE Moyenne des points par cube d'une grille.
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
    if pas <= 0
        error('vision:pcdownsample:Pas', 'Le pas de grille doit être positif.');
    end
    origine = min(points, [], 1);
    cases = floor((points - repmat(origine, size(points, 1), 1)) / pas);
    [uniques, ~, groupes] = unique(cases, 'rows');
    nombre = size(uniques, 1);
    moyennes = zeros(nombre, 3);
    premiers = zeros(nombre, 1);
    for k = 1:nombre
        garde = groupes == k;
        moyennes(k, :) = mean(points(garde, :), 1);
        indices = find(garde);
        premiers(k) = indices(1);
    end
    nuage = matlibre_nuage_copier(modele, moyennes, premiers);
end
