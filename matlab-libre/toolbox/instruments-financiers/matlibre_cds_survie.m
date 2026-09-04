function survie = matlibre_cds_survie(reglement, dates, hasard, datesHasard)
%MATLIBRE_CDS_SURVIE Probabilité de survie sous des taux de hasard constants par morceaux.
%   Le taux de hasard est la probabilité instantanée de défaut sachant
%   qu'il n'a pas encore eu lieu ; la survie est l'exponentielle de son
%   intégrale, changée de signe.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
    reglement = matlibre_dates(reglement);
    dates = matlibre_dates(dates);
    dates = dates(:);
    datesHasard = matlibre_dates(datesHasard);
    datesHasard = datesHasard(:);
    hasard = double(hasard(:));
    survie = zeros(size(dates));
    for k = 1:numel(dates)
        integrale = 0;
        precedent = reglement;
        for j = 1:numel(datesHasard)
            borne = min(datesHasard(j), dates(k));
            if borne > precedent
                integrale = integrale + hasard(j) * (borne - precedent) / 365;
                precedent = borne;
            end
            if precedent >= dates(k)
                break
            end
        end
        if dates(k) > precedent
            integrale = integrale + hasard(end) * (dates(k) - precedent) / 365;
        end
        survie(k) = exp(-integrale);
    end
end
