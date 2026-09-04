function facteurs = matlibre_courbe_escompte(courbe, dates)
%MATLIBRE_COURBE_ESCOMPTE Facteurs d'actualisation aux dates demandées.
%   Les taux sont interpolés linéairement en fonction du temps, et
%   prolongés à plat au-delà des bornes de la courbe.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
    facteurs = matlibre_interpoler_courbe(dates, courbe.Rates, courbe.EndDates, ...
                                          courbe.ValuationDate(1), ...
                                          courbe.Compounding, courbe.Basis);
end
