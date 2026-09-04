function dates = matlibre_dates_reset(reglement, echeance, frequence, regleFinMois)
%MATLIBRE_DATES_RESET Dates de fixation et de paiement d'un échéancier.
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
    if nargin < 4 || isempty(regleFinMois)
        regleFinMois = 1;
    end
    dates = matlibre_echeancier(matlibre_dates(reglement), matlibre_dates(echeance), ...
                                frequence, regleFinMois).';
end
