function [dates, precedent] = matlibre_echeancier(reglement, echeance, periode, regleFinMois)
%MATLIBRE_ECHEANCIER Dates de coupon postérieures au règlement.
%   Les dates sont construites en reculant depuis l'échéance, de douze
%   divisé par la fréquence en mois : c'est l'échéance qui fixe le
%   calendrier, non la date d'émission. PRECEDENT est la date de coupon
%   qui précède le règlement, réelle ou théorique.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
    if nargin < 4 || isempty(regleFinMois)
        regleFinMois = 1;
    end
    reglement = matlibre_dates(reglement);
    echeance = matlibre_dates(echeance);
    if periode <= 0
        dates = echeance;
        precedent = reglement;
        return
    end
    moisParPeriode = 12 / periode;
    dates = [];
    courant = echeance;
    while courant > reglement
        dates(end+1, 1) = courant;                                  %#ok<AGROW>
        courant = matlibre_reculer(echeance, numel(dates), moisParPeriode, regleFinMois);
    end
    precedent = courant;
    dates = flipud(dates(:));
end
