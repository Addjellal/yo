function t = dbDelete(t, predicat)
%DBDELETE Supprime les lignes vérifiant le prédicat.
%   T = DBDELETE(T,PREDICAT) rend la table privée des lignes que le
%   prédicat retient. Un prédicat toujours faux ne supprime rien ; un
%   prédicat toujours vrai vide la table sans la détruire.
%
%   Exemple :
%      t = dbDelete(t, @(l) l{4} < 4);       % anciennete de moins de 4 ans
%      t = dbDelete(t, @(l) true);           % vide la table
%
%   Voir aussi DBSELECT, DBUPDATE, DBTABLE.
    garde = {};
    for k = 1:numel(t.lignes)
        if ~predicat(t.lignes{k})
            garde{end+1} = t.lignes{k};
        end
    end
    t.lignes = garde;
end
