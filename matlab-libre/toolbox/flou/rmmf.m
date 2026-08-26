function fis = rmmf(fis, genre, indiceVariable, ~, indiceMf)
%RMMF Retire une fonction d'appartenance d'une variable.
%   FIS = RMMF(FIS,'input',I,'mf',J) retire la J-ième fonction
%   d'appartenance de la I-ième entrée. 'output' fait de même sur une
%   sortie.
%
%   Les règles qui s'y référaient sont retirées, et les indices supérieurs
%   sont décalés : une règle ne peut pas désigner une fonction disparue.
%
%   Exemple :
%      fis = rmmf(fis, 'input', 1, 'mf', 2);
%
%   Voir aussi ADDMF, RMVAR, ADDRULE.
    entree = estEntree(genre);
    variables = variablesDe(fis, entree);
    if indiceVariable < 1 || indiceVariable > numel(variables)
        error('fuzzy:rmmf:BadVariable', 'Variable %d inexistante.', indiceVariable);
    end
    v = variables{indiceVariable};
    if indiceMf < 1 || indiceMf > numel(v.mf)
        error('fuzzy:rmmf:BadMf', 'Fonction d''appartenance %d inexistante.', indiceMf);
    end
    v.mf(indiceMf) = [];
    variables{indiceVariable} = v;
    fis = poserVariables(fis, entree, variables);
    fis = ajusterRegles(fis, entree, indiceVariable, indiceMf);
end

function fis = ajusterRegles(fis, entree, indiceVariable, indiceMf)
%AJUSTERREGLES Retire les règles qui citaient la fonction disparue et
%   décale les indices qui la suivaient.
    if isempty(fis.regles)
        return
    end
    if entree
        colonne = indiceVariable;
    else
        colonne = numel(fis.entrees) + indiceVariable;
    end
    valeurs = fis.regles(:, colonne);
    garde = abs(valeurs) ~= indiceMf;
    fis.regles = fis.regles(garde, :);
    if isempty(fis.regles)
        return
    end
    valeurs = fis.regles(:, colonne);
    aDecaler = abs(valeurs) > indiceMf;
    valeurs(aDecaler) = valeurs(aDecaler) - sign(valeurs(aDecaler));
    fis.regles(:, colonne) = valeurs;
end
