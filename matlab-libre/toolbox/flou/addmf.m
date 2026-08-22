function fis = addmf(fis, genre, indice, nom, type, parametres)
%ADDMF Ajoute une fonction d'appartenance à une variable.
    mf = struct();
    mf.nom = nom;
    mf.type = type;
    mf.parametres = parametres;
    if strcmpi(genre, 'input')
        v = fis.entrees{indice};
        v.mf{end+1} = mf;
        fis.entrees{indice} = v;
    else
        v = fis.sorties{indice};
        v.mf{end+1} = mf;
        fis.sorties{indice} = v;
    end
end
