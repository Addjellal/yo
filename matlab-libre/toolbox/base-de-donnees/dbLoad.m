function t = dbLoad(nomFichier)
%DBLOAD Lit une table depuis un fichier CSV.
    texte = fileread(nomFichier);
    lignesTexte = strsplit(texte, sprintf('\n'));
    entete = strsplit(strtrim(lignesTexte{1}), ',');
    t = dbTable(entete);
    for k = 2:numel(lignesTexte)
        ligne = strtrim(lignesTexte{k});
        if isempty(ligne)
            continue;
        end
        champs = strsplit(ligne, ',');
        valeurs = cell(1, numel(champs));
        for j = 1:numel(champs)
            nombre = str2double(champs{j});
            if isnan(nombre)
                valeurs{j} = champs{j};
            else
                valeurs{j} = nombre;
            end
        end
        t = dbInsert(t, valeurs);
    end
end
