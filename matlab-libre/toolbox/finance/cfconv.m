function convexite = cfconv(flux, dates, rendement)
%CFCONV Convexité d'une série de flux quelconques.
%   C = CFCONV(FLUX,DATES,RENDEMENT) rend la dérivée seconde du prix par
%   rapport au rendement, rapportée au prix. CFCONV(FLUX,RENDEMENT) prend
%   des flux annuels.
%
%   Exemple :
%      cfconv([0 5 5 105], 0.06)
%
%   Voir aussi CFDUR, CFPRICE, BNDCONVY.
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
    convexite = sum(temps .* (temps + 1) .* valeurs) / (total * (1 + rendement) ^ 2);
end
