function [hasard, dates] = matlibre_cds_hasard(probabilites, reglement)
%MATLIBRE_CDS_HASARD Taux de hasard tirés de probabilités de défaut cumulées.
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
    probabilites = double(probabilites);
    dates = probabilites(:, 1);
    survie = 1 - probabilites(:, 2);
    survie = max(survie, eps);
    reglement = matlibre_dates(reglement);
    precedentes = [reglement; dates(1:end-1)];
    precedentesSurvie = [1; survie(1:end-1)];
    hasard = -log(survie ./ precedentesSurvie) ./ ((dates - precedentes) / 365);
end
