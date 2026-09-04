function series = matlibre_colonnes_marche(premier, reste, attendus)
%MATLIBRE_COLONNES_MARCHE Lit une matrice de cotations ou des vecteurs séparés.
%   ATTENDUS donne l'ordre des colonnes qu'attend l'appelant, parmi
%   'ouverture', 'haut', 'bas', 'cloture', 'volume'. Une matrice à
%   plusieurs colonnes est lue dans l'ordre ouverture, haut, bas,
%   clôture, volume — celui des tableaux de cotations ; des vecteurs
%   séparés sont pris dans l'ordre demandé.
%
%   SERIES est un tableau de cellules, une par nom attendu.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
    ordreMatrice = {'ouverture', 'haut', 'bas', 'cloture', 'volume'};
    series = cell(1, numel(attendus));
    if isempty(reste) && isnumeric(premier) && size(premier, 1) > 1 && ...
            size(premier, 2) >= 2
        for k = 1:numel(attendus)
            colonne = find(strcmp(ordreMatrice, attendus{k}));
            if isempty(colonne) || colonne > size(premier, 2)
                error('finance:colonnes:Matrice', ...
                      'La matrice de cotations n''a pas de colonne « %s ».', attendus{k});
            end
            series{k} = double(premier(:, colonne));
        end
        return
    end
    liste = [{premier}, reste];
    if numel(liste) < numel(attendus)
        error('finance:colonnes:Nombre', ...
              'Il faut %d séries, ou une matrice de cotations.', numel(attendus));
    end
    for k = 1:numel(attendus)
        series{k} = double(liste{k}(:));
    end
end
