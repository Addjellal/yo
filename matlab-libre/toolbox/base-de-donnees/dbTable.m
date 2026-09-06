function t = dbTable(colonnes)
%DBTABLE Crée une table vide dont les colonnes sont nommées.
%   T = DBTABLE({'nom','service','salaire'}) crée une table à trois
%   colonnes et aucune ligne.
%
%   La table est une valeur, non une référence : DBINSERT, DBUPDATE et
%   DBDELETE rendent une table nouvelle et laissent l'ancienne intacte.
%   C'est ce qui rend une requête sans effet de bord, et permet de
%   comparer un avant et un après sans avoir rien copié.
%
%   Une table vide reste une table : on peut la sélectionner, la grouper
%   et la vider sans cas particulier.
%
%   Exemple :
%      t = dbTable({'nom', 'age'});
%      t = dbInsert(t, {'Dupont', 42});
%      dbSelect(t, @(l) l{2} > 40)
%
%   Voir aussi DBINSERT, DBSELECT, DBUPDATE, DBDELETE, DBGROUPSUM.
    t = struct();
    t.colonnes = colonnes;
    t.lignes = {};
end
