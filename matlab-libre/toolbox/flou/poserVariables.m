function fis = poserVariables(fis, entree, variables)
%POSERVARIABLES Remplace la liste des entrées ou celle des sorties.
    if entree
        fis.entrees = variables;
    else
        fis.sorties = variables;
    end
end
