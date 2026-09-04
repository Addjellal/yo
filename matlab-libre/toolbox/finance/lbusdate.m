function jour = lbusdate(annee, mois, feries, weekend)
%LBUSDATE Dernier jour ouvré d'un mois.
%   D = LBUSDATE(ANNEE,MOIS) rend le dernier jour du mois qui ne soit ni
%   un jour de fin de semaine ni un jour férié.
%
%   Exemple :
%      datestr(lbusdate(2024, 3))     % 29-Mar-2024 : le 30 est un samedi
%
%   Voir aussi FBUSDATE, BUSDATE, ISBUSDAY, EOMDAY.
    if nargin < 3, feries = []; utiliserDefaut = true; else, utiliserDefaut = false; end
    if nargin < 4, weekend = []; end
    [annee, mois] = matlibre_diffuser_dates(annee, mois);
    jour = zeros(size(annee));
    for k = 1:numel(annee)
        courant = datenum(annee(k), mois(k), eomday(annee(k), mois(k)));
        if utiliserDefaut
            listeFeries = holidays(courant - 40, courant + 40);
        else
            listeFeries = feries;
        end
        while ~isbusday(courant, listeFeries, weekend)
            courant = courant - 1;
        end
        jour(k) = courant;
    end
end
