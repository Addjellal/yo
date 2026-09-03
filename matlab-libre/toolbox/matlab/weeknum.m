function n = weeknum(date, premierJour, europeen)
%WEEKNUM Numéro de la semaine dans l'année.
%   N = WEEKNUM(D) rend le numéro de la semaine où tombe la date D : la
%   semaine 1 est celle du 1er janvier, et les semaines commencent le
%   dimanche.
%
%   N = WEEKNUM(D,J) fait commencer la semaine au jour J (1 pour
%   dimanche, 2 pour lundi, …).
%
%   N = WEEKNUM(D,J,1) suit la règle européenne (ISO 8601) : la semaine
%   1 est celle qui contient le premier jeudi de l'année.
%
%   Exemple :
%      weeknum(datenum(2024, 1, 8))     % 2
%
%   Voir aussi WEEKDAY, CALENDAR, DATENUM, DAY.
    if nargin < 2 || isempty(premierJour)
        premierJour = 1;
    end
    if nargin < 3 || isempty(europeen)
        europeen = 0;
    end
    if ischar(date) || isstring(date) || iscell(date)
        date = datenum(date);
    end
    date = double(date);
    n = zeros(size(date));
    for k = 1:numel(date)
        n(k) = numeroSemaine(date(k), premierJour, europeen);
    end
end

function n = numeroSemaine(d, premierJour, europeen)
    v = datevec(d);
    annee = v(1);
    if europeen
        % ISO 8601 : la semaine appartient à l'année de son jeudi.
        jour = mod(weekday(d) - 2, 7);        % 0 = lundi
        jeudi = d - jour + 3;
        annee = datevec(jeudi);
        annee = annee(1);
        premierJanvier = datenum(annee, 1, 1);
        n = floor((jeudi - premierJanvier) / 7) + 1;
        return;
    end
    premierJanvier = datenum(annee, 1, 1);
    decalage = mod(weekday(premierJanvier) - premierJour, 7);
    debutSemaine1 = premierJanvier - decalage;
    n = floor((d - debutSemaine1) / 7) + 1;
end
