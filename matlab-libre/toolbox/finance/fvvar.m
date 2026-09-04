function valeur = fvvar(flux, taux, dates)
%FVVAR Valeur future d'une série de flux quelconques.
%   V = FVVAR(FLUX,TAUX) capitalise chaque flux jusqu'à la date du
%   dernier. Le premier flux est à la date zéro, et les suivants tombent
%   une période plus tard chacun.
%
%   FVVAR(FLUX,TAUX,DATES) donne les dates réelles : le taux est alors
%   annuel et les fractions d'année comptées sur 365 jours.
%
%   Exemple :
%      fvvar([-10000 2000 3000 4000 5000], 0.08)
%
%   Voir aussi PVVAR, FVFIX, IRR, NPV.
    flux = double(flux(:));
    n = numel(flux);
    if nargin < 3 || isempty(dates)
        exposants = (n - 1):-1:0;
    else
        numeros = matlibre_dates(dates);
        numeros = numeros(:);
        exposants = (numeros(end) - numeros) / 365;
    end
    valeur = sum(flux .* (1 + taux) .^ exposants(:));
end
