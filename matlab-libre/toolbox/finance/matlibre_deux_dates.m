function [a1, m1, j1, a2, m2, j2] = matlibre_deux_dates(depart, arrivee)
%MATLIBRE_DEUX_DATES Composants de deux séries de dates, diffusées.
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
    [debut, fin] = matlibre_diffuser_dates(matlibre_dates(depart), ...
                                           matlibre_dates(arrivee));
    [a1, m1, j1] = matlibre_jours_composants(debut);
    [a2, m2, j2] = matlibre_jours_composants(fin);
end
