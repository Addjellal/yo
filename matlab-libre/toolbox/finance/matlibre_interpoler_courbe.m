function facteurs = matlibre_interpoler_courbe(dates, tauxZero, datesCourbe, reglement, composition, base)
%MATLIBRE_INTERPOLER_COURBE Facteurs d'actualisation à des dates quelconques.
%   Les taux zéro-coupon sont interpolés linéairement en fonction du
%   temps, et prolongés à plat au-delà des bornes de la courbe.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
    datesCourbe = matlibre_dates(datesCourbe);
    datesCourbe = datesCourbe(:);
    reglement = matlibre_dates(reglement);
    tempsCourbe = zeros(size(datesCourbe));
    for k = 1:numel(datesCourbe)
        tempsCourbe(k) = yearfrac(reglement, datesCourbe(k), base);
    end
    dates = matlibre_dates(dates);
    dates = dates(:);
    temps = zeros(size(dates));
    for k = 1:numel(dates)
        temps(k) = yearfrac(reglement, dates(k), base);
    end
    tauxZero = double(tauxZero(:));
    if numel(tempsCourbe) == 1
        taux = repmat(tauxZero(1), size(temps));
    else
        taux = interp1(tempsCourbe, tauxZero, temps, 'linear', 'extrap');
        taux(temps < tempsCourbe(1)) = tauxZero(1);
        taux(temps > tempsCourbe(end)) = tauxZero(end);
    end
    facteurs = matlibre_escompte(taux, temps, composition);
end
