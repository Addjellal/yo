function [debut, fin] = thirdwednesday(mois, annee)
%THIRDWEDNESDAY Troisième mercredi du mois, et celui de trois mois plus tard.
%   [D,F] = THIRDWEDNESDAY(MOIS,ANNEE) rend le troisième mercredi du mois
%   et celui du mois qui vient trois mois après. Ce sont les dates de
%   début et de fin de la période couverte par un contrat à terme sur
%   taux à trois mois : c'est ce jour-là que se règlent les eurodollars.
%
%   Exemple :
%      [d, f] = thirdwednesday(3, 2024);
%      datestr([d f])          % 20-Mar-2024 et 19-Jun-2024
%
%   Voir aussi NWEEKDATE, LWEEKDATE, HOLIDAYS.
    [mois, annee] = matlibre_diffuser_dates(mois, annee);
    debut = nweekdate(3, 4, annee, mois);
    moisFin = mois + 3;
    anneeFin = annee + floor((moisFin - 1) / 12);
    moisFin = mod(moisFin - 1, 12) + 1;
    fin = nweekdate(3, 4, anneeFin, moisFin);
end
