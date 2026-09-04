function nombre = days360(depart, arrivee)
%DAYS360 Nombre de jours, convention 30/360 américaine.
%   N = DAYS360(D1,D2) compte les jours en supposant douze mois de trente
%   jours. C'est la convention des obligations d'entreprise américaines :
%   elle rend tous les coupons semestriels égaux, ce que le calendrier
%   réel ne fait pas.
%
%   Le trente et unième jour d'un mois compte pour le trentième ; si la
%   date d'arrivée tombe un trente et un et que celle de départ est déjà
%   ramenée au trente, elle l'est aussi.
%
%   Exemple :
%      days360('01-Jan-2000', '01-Jan-2001')     % 360
%      days360('31-Jan-2000', '29-Feb-2000')     % 29
%
%   Voir aussi DAYS360E, DAYS360ISDA, DAYS360PSA, DAYS365, DAYSACT, YEARFRAC.
    [a1, m1, j1, a2, m2, j2] = matlibre_deux_dates(depart, arrivee);
    j1(j1 == 31) = 30;
    ajuster = (j2 == 31) & (j1 >= 30);
    j2(ajuster) = 30;
    nombre = 360 * (a2 - a1) + 30 * (m2 - m1) + (j2 - j1);
end
