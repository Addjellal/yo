function valeur = pvvar(flux, taux, dates)
%PVVAR Valeur actuelle d'une série de flux quelconques.
%   V = PVVAR(FLUX,TAUX) actualise chaque flux à la date du premier. Le
%   premier flux est à la date zéro.
%
%   PVVAR(FLUX,TAUX,DATES) donne les dates réelles : le taux est alors
%   annuel et les fractions d'année comptées sur 365 jours.
%
%   La valeur actuelle est nulle quand le taux vaut le taux de rendement
%   interne : c'est la définition de celui-ci.
%
%   Exemple :
%      pvvar([-10000 2000 3000 4000 5000], 0.08)
%
%   Voir aussi FVVAR, PVFIX, IRR, NPV, MIRR.
    flux = double(flux(:));
    n = numel(flux);
    if nargin < 3 || isempty(dates)
        exposants = 0:(n - 1);
    else
        numeros = matlibre_dates(dates);
        numeros = numeros(:);
        exposants = (numeros - numeros(1)) / 365;
    end
    valeur = sum(flux ./ (1 + taux) .^ exposants(:));
end
