function excel = m2xdate(dates, convention)
%M2XDATE Numéro de série MATLAB converti en numéro Excel.
%   E = M2XDATE(D) convertit vers le système de 1900, celui d'Excel sous
%   Windows. M2XDATE(D,1) convertit vers celui de 1904.
%
%   Le système de 1900 tient le 29 février 1900 pour un jour existant, ce
%   qui est faux : 1900 n'était pas bissextile. L'écart constant de
%   693960 jours reproduit cette erreur, sans quoi les dates postérieures
%   à février 1900 seraient décalées d'un jour.
%
%   Exemple :
%      m2xdate(datenum(2000, 1, 1))     % 36526
%
%   Voir aussi X2MDATE, DATENUM, DATESTR.
    if nargin < 2 || isempty(convention)
        convention = 0;
    end
    numeros = matlibre_dates(dates);
    if convention == 1
        excel = numeros - 695422;
    else
        excel = numeros - 693960;
    end
end
