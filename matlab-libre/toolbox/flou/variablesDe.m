function variables = variablesDe(fis, entree)
%VARIABLESDE Liste des variables d'entrée ou de sortie d'un système flou.
    if entree
        variables = fis.entrees;
    else
        variables = fis.sorties;
    end
end
