function jours = holidays(depart, arrivee)
%HOLIDAYS Jours fériés des marchés américains.
%   H = HOLIDAYS(D1,D2) rend les jours où le marché de New York est
%   fermé, entre les deux dates. Sans argument, l'intervalle va de 1950 à
%   2100.
%
%   Les dates sont calculées à partir des règles, non lues dans une
%   table : jour de l'an, anniversaire de Martin Luther King le troisième
%   lundi de janvier, anniversaire de Washington le troisième lundi de
%   février, vendredi saint, jour du Souvenir le dernier lundi de mai,
%   Juneteenth depuis 2022, fête nationale le 4 juillet, fête du travail
%   le premier lundi de septembre, Thanksgiving le quatrième jeudi de
%   novembre et Noël. Un jour férié tombant un samedi est chômé la veille,
%   un dimanche le lendemain.
%
%   Exemple :
%      datestr(holidays('01-Jan-2024', '31-Dec-2024'))
%
%   Voir aussi ISBUSDAY, BUSDATE, LBUSDATE, FBUSDATE.
    if nargin < 1 || isempty(depart)
        depart = datenum(1950, 1, 1);
    end
    if nargin < 2 || isempty(arrivee)
        arrivee = datenum(2100, 12, 31);
    end
    depart = matlibre_dates(depart);
    arrivee = matlibre_dates(arrivee);
    composants = datevec([min(depart(:)); max(arrivee(:))]);
    jours = [];
    for annee = composants(1, 1):composants(2, 1)
        jours = [jours; matlibre_feries_annee(annee)];   %#ok<AGROW>
    end
    jours = unique(jours);
    jours = jours(jours >= floor(min(depart(:))) & jours <= floor(max(arrivee(:))));
end
