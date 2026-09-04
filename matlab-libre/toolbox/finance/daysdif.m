function nombre = daysdif(depart, arrivee, base)
%DAYSDIF Nombre de jours entre deux dates, selon une convention de calcul.
%   N = DAYSDIF(D1,D2,BASE) compte les jours comme le fait la convention
%   BASE — le numérateur de YEARFRAC, avant division par la longueur de
%   l'année. Les bases sont celles de YEARFRAC.
%
%   Exemple :
%      daysdif('01-Jan-2000', '01-Jan-2001', 0)   % 366
%      daysdif('01-Jan-2000', '01-Jan-2001', 1)   % 360
%
%   Voir aussi YEARFRAC, DAYS360, DAYS365, DAYSACT.
    if nargin < 3 || isempty(base)
        base = 0;
    end
    [debut, fin] = matlibre_diffuser_dates(matlibre_dates(depart), matlibre_dates(arrivee));
    [debut, base] = matlibre_diffuser_dates(debut, matlibre_dates(base));
    [fin, base] = matlibre_diffuser_dates(fin, base);
    nombre = zeros(size(debut));
    for k = 1:numel(debut)
        switch round(base(k))
            case 1,  nombre(k) = days360(debut(k), fin(k));
            case 4,  nombre(k) = days360psa(debut(k), fin(k));
            case 5,  nombre(k) = days360isda(debut(k), fin(k));
            case {6, 11}, nombre(k) = days360e(debut(k), fin(k));
            case 7,  nombre(k) = days365(debut(k), fin(k));
            case 13, nombre(k) = numel(matlibre_jours_ouvres(debut(k), fin(k)));
            otherwise, nombre(k) = daysact(debut(k), fin(k));
        end
    end
end
