function ouvre = isbusday(dates, feries, weekend)
%ISBUSDAY Le jour est-il ouvré ?
%   O = ISBUSDAY(D) vaut un quand D n'est ni un samedi, ni un dimanche,
%   ni un jour férié des marchés américains.
%
%   ISBUSDAY(D,FERIES) donne la liste des jours chômés à retenir ; une
%   liste vide veut dire « aucun ». ISBUSDAY(D,FERIES,WEEKEND) décrit la
%   semaine par sept indicateurs, du dimanche au samedi, un signifiant
%   chômé : [1 0 0 0 0 0 1] est le défaut.
%
%   Exemple :
%      isbusday('04-Jul-2024')       % 0 : fete nationale
%      isbusday('05-Jul-2024')       % 1
%
%   Voir aussi BUSDATE, HOLIDAYS, LBUSDATE, FBUSDATE, WRKDYDIF.
    numeros = floor(matlibre_dates(dates));
    if nargin < 2
        feries = holidays(min(numeros(:)) - 400, max(numeros(:)) + 400);
    elseif ~isempty(feries)
        feries = floor(matlibre_dates(feries));
    end
    if nargin < 3 || isempty(weekend)
        weekend = [1 0 0 0 0 0 1];
    end
    weekend = logical(weekend(:).');
    jour = weekday(numeros);
    ouvre = ~weekend(jour);
    ouvre = reshape(ouvre, size(numeros));
    if ~isempty(feries)
        ouvre = ouvre & ~ismember(numeros, feries(:).');
    end
end
