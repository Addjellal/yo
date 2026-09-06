function indices = matlibre_stat_indicesGroupes(groupes)
%MATLIBRE_STAT_INDICESGROUPES Numérote les groupes d'une liste quelconque.
%   Une liste de nombres, de chaînes ou de catégories devient une liste
%   d'entiers, un par valeur distincte. C'est ce qu'il faut pour
%   stratifier un découpage sans se soucier du type des étiquettes.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
    if iscell(groupes) || isstring(groupes)
        [~, ~, indices] = unique(cellstr(groupes));
    elseif iscategorical(groupes)
        [~, ~, indices] = unique(cellstr(groupes));
    else
        [~, ~, indices] = unique(double(groupes(:)));
    end
    indices = indices(:);
end
