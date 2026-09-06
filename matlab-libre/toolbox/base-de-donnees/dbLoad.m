function t = dbLoad(nomFichier)
%DBLOAD Lit une table depuis un fichier CSV.
%   T = DBLOAD(FICHIER) lit un fichier écrit par DBSAVE : la première
%   ligne donne les noms de colonnes, les suivantes les enregistrements.
%
%   Les champs qui se convertissent en nombre reviennent en nombres, les
%   autres restent des chaînes. C'est la seule reconstruction de type
%   possible d'un format qui n'en porte pas — et elle se trompe sur un
%   identifiant tout en chiffres, qu'elle rendra numérique.
%
%   L'aller-retour DBSAVE puis DBLOAD est la vérification qui compte :
%   la table relue doit se comporter comme l'originale, groupements
%   compris.
%
%   Exemple :
%      dbSave(t, 'personnel.csv');
%      relue = dbLoad('personnel.csv');
%      isequal(relue.colonnes, t.colonnes)     % true
%
%   Voir aussi DBSAVE, DBTABLE, READTABLE.
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
