function t = dbDelete(t, predicat)
%DBDELETE Supprime les lignes vérifiant le prédicat.
    garde = {};
    for k = 1:numel(t.lignes)
        if ~predicat(t.lignes{k})
            garde{end+1} = t.lignes{k};
        end
    end
    t.lignes = garde;
end
