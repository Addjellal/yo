function nombre = days360isda(depart, arrivee)
%DAYS360ISDA Nombre de jours, convention 30/360 de l'ISDA.
%   Le trente et unième jour est ramené au trente des deux côtés, comme
%   dans la convention européenne, et la fin de février n'est pas
%   allongée.
%
%   Voir aussi DAYS360, DAYS360E, DAYS360PSA, YEARFRAC.
    nombre = days360e(depart, arrivee);
end
