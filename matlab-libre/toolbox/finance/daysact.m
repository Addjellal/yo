function nombre = daysact(depart, arrivee)
%DAYSACT Nombre de jours réels entre deux dates.
%   N = DAYSACT(D1,D2) rend D2 moins D1, en jours de calendrier. Avec un
%   seul argument, DAYSACT(D) compte depuis le 31 décembre de l'an zéro,
%   ce qui est le numéro de série lui-même.
%
%   Exemple :
%      daysact('01-Jan-2000', '01-Jan-2001')     % 366, annee bissextile
%
%   Voir aussi DAYSDIF, DAYS360, DAYS365, YEARFRAC.
    debut = matlibre_dates(depart);
    if nargin < 2
        nombre = floor(debut);
        return
    end
    [debut, fin] = matlibre_diffuser_dates(debut, matlibre_dates(arrivee));
    nombre = floor(fin) - floor(debut);
end
