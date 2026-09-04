function nombre = days360e(depart, arrivee)
%DAYS360E Nombre de jours, convention 30/360 européenne.
%   La différence avec DAYS360 tient au trente et unième jour de la date
%   d'arrivée : ici il est toujours ramené au trente, quelle que soit la
%   date de départ.
%
%   Exemple :
%      days360('01-Jan-2000', '31-Dec-2000')     % 360
%      days360e('01-Jan-2000', '31-Dec-2000')    % 359
%
%   Voir aussi DAYS360, DAYS360ISDA, DAYS360PSA, YEARFRAC.
    [a1, m1, j1, a2, m2, j2] = matlibre_deux_dates(depart, arrivee);
    j1(j1 == 31) = 30;
    j2(j2 == 31) = 30;
    nombre = 360 * (a2 - a1) + 30 * (m2 - m1) + (j2 - j1);
end
