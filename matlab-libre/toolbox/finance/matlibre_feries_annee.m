function jours = matlibre_feries_annee(annee)
%MATLIBRE_FERIES_ANNEE Jours fériés du marché de New York pour une année.
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
    jours = [];
    % Jour de l'an : quand il tombe un samedi, le marché ne ferme pas le
    % vendredi 31 décembre de l'année précédente.
    premier = datenum(annee, 1, 1);
    if weekday(premier) == 1
        jours(end+1, 1) = premier + 1;
    elseif weekday(premier) ~= 7
        jours(end+1, 1) = premier;
    end
    if annee >= 1998
        jours(end+1, 1) = nweekdate(3, 2, annee, 1);      % Martin Luther King
    end
    jours(end+1, 1) = nweekdate(3, 2, annee, 2);          % anniversaire de Washington
    jours(end+1, 1) = matlibre_paques(annee) - 2;         % vendredi saint
    jours(end+1, 1) = lweekdate(2, annee, 5);             % jour du Souvenir
    if annee >= 2022
        jours(end+1, 1) = observe(datenum(annee, 6, 19)); % Juneteenth
    end
    jours(end+1, 1) = observe(datenum(annee, 7, 4));      % fête nationale
    jours(end+1, 1) = nweekdate(1, 2, annee, 9);          % fête du travail
    jours(end+1, 1) = nweekdate(4, 5, annee, 11);         % Thanksgiving
    jours(end+1, 1) = observe(datenum(annee, 12, 25));    % Noël
    jours = sort(jours);
end

function d = observe(d)
%OBSERVE Décale un jour férié tombant un samedi ou un dimanche.
    switch weekday(d)
        case 7, d = d - 1;   % samedi : chômé le vendredi
        case 1, d = d + 1;   % dimanche : chômé le lundi
    end
end
