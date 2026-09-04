function valeurs = matlibre_score_poids(grille, nom, indices)
%MATLIBRE_SCORE_POIDS Poids de la preuve de chaque observation.
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
    colonne = grille.Data.(nom);
    [indicesApprentissage, etiquettes] = matlibre_score_indices(grille, nom, colonne);
    [bons, mauvais, poids] = matlibre_score_reponse(grille);
    nombre = numel(etiquettes);
    table = zeros(nombre, 1);
    compteBons = zeros(nombre, 1);
    compteMauvais = zeros(nombre, 1);
    for k = 1:nombre
        garde = indicesApprentissage == k;
        compteBons(k) = sum(poids(garde) .* bons(garde));
        compteMauvais(k) = sum(poids(garde) .* mauvais(garde));
    end
    totalBons = max(sum(compteBons), eps);
    totalMauvais = max(sum(compteMauvais), eps);
    partBons = compteBons / totalBons;
    partMauvais = compteMauvais / totalMauvais;
    partBons(partBons == 0) = 0.5 / totalBons;
    partMauvais(partMauvais == 0) = 0.5 / totalMauvais;
    table = log(partBons ./ partMauvais);
    table(compteBons + compteMauvais == 0) = 0;
    indices = min(max(round(indices(:)), 1), nombre);
    valeurs = table(indices);
end
