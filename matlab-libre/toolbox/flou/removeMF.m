function fis = removeMF(fis, variable, modalite)
%REMOVEMF Retire une modalité d'une variable.
%   FIS = REMOVEMF(FIS,VAR,MF) retire de la variable VAR — nommée ou de
%   rang — la modalité MF, nommée ou de rang. Les règles qui la
%   mentionnaient sont supprimées, et celles qui nomment une modalité de
%   rang supérieur sont renumérotées : sans cela elles désigneraient la
%   mauvaise.
%
%   Exemple :
%      fis = addInput(mamfis, [0 1], 'Name', 'a', 'NumMFs', 3);
%      fis = removeMF(fis, 'a', 'mf2');
%      numel(fis.entrees{1}.mf)       % 2
%
%   Voir aussi ADDMF, REMOVEINPUT, REMOVERULE, RMMF.
    [entree, indiceVariable] = trouverVariable(fis, variable);
    variables = variablesDe(fis, entree);
    liste = variables{indiceVariable}.mf;
    indiceMf = rangDeModalite(liste, modalite, variables{indiceVariable}.nom);
    if entree
        genre = 'input';
    else
        genre = 'output';
    end
    fis = rmmf(fis, genre, indiceVariable, 'mf', indiceMf);
end

function indice = rangDeModalite(liste, modalite, nomVariable)
    if isnumeric(modalite)
        indice = round(modalite);
        if indice < 1 || indice > numel(liste)
            error('fuzzy:removeMF:Rang', 'Modalité %d inexistante.', indice);
        end
        return
    end
    nom = char(modalite);
    for k = 1:numel(liste)
        if strcmp(liste{k}.nom, nom)
            indice = k;
            return
        end
    end
    error('fuzzy:removeMF:Absente', ...
          'La variable ''%s'' n''a pas de modalité ''%s''.', nomVariable, nom);
end
