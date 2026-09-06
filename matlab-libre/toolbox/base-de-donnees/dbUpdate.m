function t = dbUpdate(t, predicat, colonne, valeur)
%DBUPDATE Met à jour une colonne pour les lignes retenues.
%   T = DBUPDATE(T,PREDICAT,COLONNE,VALEUR) écrit VALEUR dans la colonne
%   nommée, pour toutes les lignes que le prédicat retient. Les autres ne
%   bougent pas, et la table d'origine non plus.
%
%   La colonne se désigne ici par son nom, alors que le prédicat lit par
%   rang : c'est voulu. Le prédicat parcourt une ligne quelconque, la
%   colonne écrite est connue à l'avance.
%
%   Exemple :
%      t = dbUpdate(t, @(l) strcmp(l{2}, 'ventes'), 'salaire', 45000);
%
%   Voir aussi DBSELECT, DBDELETE, DBINSERT.
    j = find(strcmp(t.colonnes, colonne), 1);
    for k = 1:numel(t.lignes)
        if predicat(t.lignes{k})
            ligne = t.lignes{k};
            ligne{j} = valeur;
            t.lignes{k} = ligne;
        end
    end
end
