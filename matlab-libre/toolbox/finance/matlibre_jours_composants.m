function [annee, mois, jour] = matlibre_jours_composants(dates)
%MATLIBRE_JOURS_COMPOSANTS Année, mois et jour d'une série de dates.
%   Les dates peuvent être des numéros de série, du texte ou un tableau
%   de cellules ; la forme du résultat suit celle de l'entrée numérique.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
    numeros = matlibre_dates(dates);
    composants = datevec(numeros(:));
    annee = reshape(composants(:, 1), size(numeros));
    mois = reshape(composants(:, 2), size(numeros));
    jour = reshape(composants(:, 3), size(numeros));
end
