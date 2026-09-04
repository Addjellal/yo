function nombre = days365(depart, arrivee)
%DAYS365 Nombre de jours, année de 365 jours.
%   N = DAYS365(D1,D2) compte les jours en ignorant les 29 février :
%   chaque année compte trois cent soixante-cinq jours, et le rang du
%   jour dans l'année se lit sur un calendrier non bissextile.
%
%   Exemple :
%      days365('01-Jan-2000', '01-Jan-2001')     % 365
%      daysact('01-Jan-2000', '01-Jan-2001')     % 366
%
%   Voir aussi DAYS360, DAYSACT, DAYSDIF, YEARFRAC.
    [a1, m1, j1, a2, m2, j2] = matlibre_deux_dates(depart, arrivee);
    nombre = 365 * (a2 - a1) + matlibre_rang_jour(m2, j2) - matlibre_rang_jour(m1, j1);
end
