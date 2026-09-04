function jour = datewrkdy(depart, nombreJours, nombreFeries)
%DATEWRKDY Date située un nombre de jours ouvrés plus loin.
%   D = DATEWRKDY(DEPART,N) avance de N jours ouvrés, en sautant les
%   samedis et les dimanches. DATEWRKDY(DEPART,N,F) traite en plus F
%   jours fériés : ils sont ajoutés au décompte, comme le fait MATLAB,
%   sans qu'on ait à dire lesquels.
%
%   Exemple :
%      datestr(datewrkdy('01-Mar-2024', 5))    % 08-Mar-2024
%
%   Voir aussi WRKDYDIF, BUSDATE, ISBUSDAY, HOLIDAYS.
    if nargin < 3 || isempty(nombreFeries)
        nombreFeries = 0;
    end
    [debut, nombreJours] = matlibre_diffuser_dates(matlibre_dates(depart), nombreJours);
    [debut, nombreFeries] = matlibre_diffuser_dates(debut, nombreFeries);
    jour = zeros(size(debut));
    for k = 1:numel(debut)
        restants = round(nombreJours(k)) + round(nombreFeries(k)) - 1;
        courant = floor(debut(k));
        pas = 1;
        if restants < 0
            pas = -1;
            restants = -restants;
        end
        for compte = 1:restants
            courant = courant + pas;
            while any(weekday(courant) == [1 7])
                courant = courant + pas;
            end
        end
        jour(k) = courant;
    end
end
