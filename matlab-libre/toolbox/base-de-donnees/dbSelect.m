function lignes = dbSelect(t, predicat)
%DBSELECT Sélectionne les lignes vérifiant un prédicat.
%   LIGNES = DBSELECT(T,@(ligne) ...) ; sans prédicat, rend toute la table.
    lignes = {};
    for k = 1:numel(t.lignes)
        if nargin < 2 || isempty(predicat) || predicat(t.lignes{k})
            lignes{end+1} = t.lignes{k};
        end
    end
end
