function d = time(cd)
%TIME Partie horaire d'une durée de calendrier, sous forme de duration.
%   D = TIME(CD) extrait d'une durée de calendrier la part qui est une
%   durée exacte — heures, minutes, secondes — et la rend en duration.
%
%   Une durée de calendrier mêle deux natures : des mois et des jours, qui
%   n'ont pas de longueur fixe, et un temps d'horloge, qui en a une. TIME
%   sépare la seconde de la première, et c'est la seule part qu'on puisse
%   convertir en secondes sans connaître la date de départ.
%
%   Exemple :
%      cd = calmonths(2) + hours(5);
%      time(cd)                        % 05:00:00
%      seconds(time(cd))               % 18000
%
%   Voir aussi CALENDARDURATION, CALMONTHS, DURATION, HOURS.
    if isa(cd, 'calendarDuration')
        d = duration.avec(cd.Temps, 'hh:mm:ss');
    else
        d = duration(cd);
    end
end
