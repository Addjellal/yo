function nombre = wrkdydif(depart, arrivee, nombreFeries)
%WRKDYDIF Nombre de jours ouvrés entre deux dates.
%   N = WRKDYDIF(D1,D2) compte les jours ouvrés du premier au second,
%   bornes comprises. WRKDYDIF(D1,D2,F) retranche F jours fériés.
%
%   Exemple :
%      wrkdydif('01-Mar-2024', '08-Mar-2024')    % 6
%
%   Voir aussi DATEWRKDY, BUSDATE, ISBUSDAY, HOLIDAYS.
    if nargin < 3 || isempty(nombreFeries)
        nombreFeries = 0;
    end
    [debut, fin] = matlibre_diffuser_dates(matlibre_dates(depart), matlibre_dates(arrivee));
    [debut, nombreFeries] = matlibre_diffuser_dates(debut, nombreFeries);
    [fin, nombreFeries] = matlibre_diffuser_dates(fin, nombreFeries);
    nombre = zeros(size(debut));
    for k = 1:numel(debut)
        signe = 1;
        a = floor(debut(k));
        b = floor(fin(k));
        if b < a
            [a, b] = deal(b, a);
            signe = -1;
        end
        jours = a:b;
        ouvres = sum(~ismember(weekday(jours), [1 7]));
        nombre(k) = signe * (ouvres - round(nombreFeries(k)));
    end
end
