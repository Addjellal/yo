function noms = matlibre_noms_modele(specification)
%MATLIBRE_NOMS_MODELE Liste de noms, quelle qu'en soit l'écriture.
%   N = MATLIBRE_NOMS_MODELE(S) accepte une chaîne, un tableau de cellules
%   de chaînes ou un tableau de chaînes, et rend un tableau de cellules.
%
%   Exemple :
%      matlibre_noms_modele('a')        % {'a'}
%
%   Voir aussi FITTYPE.
    if isempty(specification)
        noms = {};
    elseif ischar(specification)
        noms = {strtrim(specification)};
    elseif iscell(specification)
        noms = cell(1, numel(specification));
        for k = 1:numel(specification)
            noms{k} = strtrim(char(specification{k}));
        end
    else
        noms = cellstr(specification);
        noms = noms(:).';
    end
end
