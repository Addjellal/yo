function nombre = days360psa(depart, arrivee)
%DAYS360PSA Nombre de jours, convention 30/360 de la PSA.
%   Elle suit la convention américaine, avec une règle de plus : si la
%   date de départ est le dernier jour de février, elle compte pour un
%   trente. Sans quoi un coupon partant du 28 février serait plus court
%   que les autres.
%
%   Voir aussi DAYS360, DAYS360E, DAYS360ISDA, YEARFRAC.
    [a1, m1, j1, a2, m2, j2] = matlibre_deux_dates(depart, arrivee);
    finFevrier = (m1 == 2) & (j1 == eomday(a1, m1));
    j1(finFevrier) = 30;
    j1(j1 == 31) = 30;
    ajuster = (j2 == 31) & (j1 >= 30);
    j2(ajuster) = 30;
    nombre = 360 * (a2 - a1) + 30 * (m2 - m1) + (j2 - j1);
end
