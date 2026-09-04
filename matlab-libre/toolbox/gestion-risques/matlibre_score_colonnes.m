function colonnes = matlibre_score_colonnes(donnees)
%MATLIBRE_SCORE_COLONNES Ramène un tableau de données à une structure.
%   Accepte une table, une structure de colonnes ou un tableau de
%   cellules dont la première ligne porte les noms.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
    if isstruct(donnees) && ~isa(donnees, 'table')
        colonnes = donnees;
        return
    end
    if isa(donnees, 'table')
        noms = donnees.Properties.VariableNames;
        colonnes = struct();
        for k = 1:numel(noms)
            colonnes.(noms{k}) = donnees.(noms{k});
        end
        return
    end
    if iscell(donnees)
        noms = donnees(1, :);
        colonnes = struct();
        for k = 1:numel(noms)
            colonne = donnees(2:end, k);
            if all(cellfun(@isnumeric, colonne))
                colonnes.(char(noms{k})) = cell2mat(colonne);
            else
                colonnes.(char(noms{k})) = colonne;
            end
        end
        return
    end
    error('risque:creditscorecard:Donnees', ...
          'Les données doivent être une table, une structure ou un tableau de cellules.');
end
