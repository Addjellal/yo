function [duree, dureeModifiee] = cfdur(flux, dates, rendement)
%CFDUR Duration d'une série de flux quelconques.
%   [D,DM] = CFDUR(FLUX,DATES,RENDEMENT) rend la duration de Macaulay,
%   en années, et la sensibilité modifiée. Le rendement est annuel, à
%   capitalisation annuelle.
%
%   CFDUR(FLUX,RENDEMENT) prend les flux à des dates entières, une par
%   an, le premier à la date zéro.
%
%   Exemple :
%      cfdur([0 5 5 105], 0.06)
%
%   Voir aussi CFCONV, CFPRICE, CFYIELD, BNDDURY.
    if nargin < 3
        rendement = dates;
        temps = (0:(numel(flux) - 1)).';
    else
        numeros = matlibre_dates(dates);
        temps = (numeros(:) - numeros(1)) / 365;
    end
    flux = double(flux(:));
    valeurs = flux ./ (1 + rendement) .^ temps;
    total = sum(valeurs);
    duree = sum(temps .* valeurs) / total;
    dureeModifiee = duree / (1 + rendement);
end
