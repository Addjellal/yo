function t = timezones(zone)
%TIMEZONES Liste des fuseaux horaires reconnus.
%   T = TIMEZONES rend une table des fuseaux, de leur décalage d'hiver en
%   heures et de la règle d'heure d'été qu'ils suivent.
%   T = TIMEZONES(REGION) ne garde que les fuseaux dont le nom commence
%   par REGION, par exemple 'Europe' ou 'America'.
%
%   Ce n'est pas la base IANA complète : c'est une sélection des fuseaux
%   les plus employés, avec les règles en vigueur depuis 2007. Les
%   changements historiques ne sont pas suivis, et un décalage fixe écrit
%   '+02:00' est toujours accepté par DATETIME sans figurer ici.
%
%   Exemple :
%      height(timezones('Europe'))
%
%   Voir aussi DATETIME, TZOFFSET, ISDST.
    [noms, decalages, familles] = datetime.tableFuseaux();
    if nargin >= 1 && ~isempty(zone)
        prefixe = char(zone);
        garde = false(1, numel(noms));
        for k = 1:numel(noms)
            garde(k) = numel(noms{k}) >= numel(prefixe) && ...
                       strcmpi(noms{k}(1:numel(prefixe)), prefixe);
        end
        noms = noms(garde);
        decalages = decalages(garde);
        familles = familles(garde);
    end
    t = table(noms(:), decalages(:), familles(:), ...
              'VariableNames', {'Name', 'UTCOffset', 'DSTRule'});
end
