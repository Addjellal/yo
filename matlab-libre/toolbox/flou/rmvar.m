function fis = rmvar(fis, genre, indiceVariable)
%RMVAR Retire une variable d'entrée ou de sortie.
%   FIS = RMVAR(FIS,'input',I) retire la I-ième entrée, et avec elle la
%   colonne correspondante de la matrice des règles.
%
%   Exemple :
%      fis = rmvar(fis, 'input', 2);
%
%   Voir aussi ADDVAR, RMMF.
    entree = estEntree(genre);
    variables = variablesDe(fis, entree);
    if indiceVariable < 1 || indiceVariable > numel(variables)
        error('fuzzy:rmvar:BadVariable', 'Variable %d inexistante.', indiceVariable);
    end
    if entree
        colonne = indiceVariable;
    else
        colonne = numel(fis.entrees) + indiceVariable;
    end
    variables(indiceVariable) = [];
    fis = poserVariables(fis, entree, variables);
    if ~isempty(fis.regles)
        fis.regles(:, colonne) = [];
    end
end
