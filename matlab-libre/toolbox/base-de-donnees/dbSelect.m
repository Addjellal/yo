function lignes = dbSelect(t, predicat)
%DBSELECT Sélectionne les lignes vérifiant un prédicat.
%   LIGNES = DBSELECT(T,PREDICAT) rend les lignes pour lesquelles le
%   prédicat est vrai, sous forme d'un tableau de cellules.
%   DBSELECT(T) sans prédicat rend toute la table.
%
%   Le prédicat reçoit la ligne entière, et lit ses colonnes par leur
%   rang : @(l) l{3} > 40000 porte sur la troisième colonne. Les
%   conditions se composent avec && et || comme partout ailleurs, ce qui
%   remplace le « WHERE » d'un langage de requête.
%
%   Un prédicat toujours faux rend une liste vide, non une erreur : c'est
%   un résultat, et le programme appelant doit pouvoir le traiter comme
%   tel.
%
%   Exemple :
%      dbSelect(t, @(l) strcmp(l{2}, 'etudes'))
%      dbSelect(t, @(l) l{3} > 40000 && l{4} > 4)
%      dbSelect(t)                     % toute la table
%
%   Voir aussi DBTABLE, DBUPDATE, DBDELETE, DBGROUPSUM.
    lignes = {};
    for k = 1:numel(t.lignes)
        if nargin < 2 || isempty(predicat) || predicat(t.lignes{k})
            lignes{end+1} = t.lignes{k};
        end
    end
end
