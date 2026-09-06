function fis = rmvar(fis, genre, indiceVariable)
%RMVAR Retire une variable d'entrée ou de sortie.
%   FIS = RMVAR(FIS,'input',I) retire la I-ième entrée, et avec elle la
%   colonne correspondante de la matrice des règles.
%
%   Exemple :
%      fis = addInput(mamfis('Name', 'pilote'), [0 10], 'Name', 'erreur');
%      fis = addMF(fis, 'erreur', 'trimf', [0 0 5], 'Name', 'petite');
%      fis = addMF(fis, 'erreur', 'trimf', [5 10 10], 'Name', 'grande');
%      fis = addOutput(fis, [0 1], 'Name', 'commande');
%      fis = addMF(fis, 'commande', 'trimf', [0 0 0.5], 'Name', 'faible');
%      fis = addMF(fis, 'commande', 'trimf', [0.5 1 1], 'Name', 'forte');
%      fis = addRule(fis, [1 1 1 1; 2 2 1 1]);
%      fis = addInput(fis, [0 1], 'Name', 'derivee');
%      fis = rmvar(fis, 'input', 2);
%      numel(variablesDe(fis, true))     % 1 : il n'en reste qu'une
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
