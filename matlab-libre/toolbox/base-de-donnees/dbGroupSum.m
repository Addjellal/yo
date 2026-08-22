function [cles, sommes] = dbGroupSum(t, colonneCle, colonneValeur)
%DBGROUPSUM Somme d'une colonne, groupée par une autre.
    a = find(strcmp(t.colonnes, colonneCle), 1);
    b = find(strcmp(t.colonnes, colonneValeur), 1);
    cles = {};
    sommes = [];
    for k = 1:numel(t.lignes)
        ligne = t.lignes{k};
        cle = ligne{a};
        if ~ischar(cle)
            cle = sprintf('%g', cle);
        end
        indice = find(strcmp(cles, cle), 1);
        if isempty(indice)
            cles{end+1} = cle;
            sommes(end+1) = ligne{b};
        else
            sommes(indice) = sommes(indice) + ligne{b};
        end
    end
end
