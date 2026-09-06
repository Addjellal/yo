function [hasard, dates] = matlibre_cds_hasard(probabilites, reglement)
%MATLIBRE_CDS_HASARD Taux de hasard tirés de probabilités de défaut cumulées.
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
    probabilites = double(probabilites);
    dates = probabilites(:, 1);
    survie = 1 - probabilites(:, 2);
    survie = max(survie, eps);
    reglement = matlibre_dates(reglement);
    % Sur une courbe a un seul point, DATES(1:END-1) est vide en ligne et
    % non en colonne : sans remise en forme, l'empilement echoue et le
    % cas le plus simple — une seule echeance cotee — cesse de marcher.
    precedentes = [reglement(1); reshape(dates(1:end-1), [], 1)];
    precedentesSurvie = [1; reshape(survie(1:end-1), [], 1)];
    dates = reshape(dates, [], 1);
    survie = reshape(survie, [], 1);
    hasard = -log(survie ./ precedentesSurvie) ./ ((dates - precedentes) / 365);
end
