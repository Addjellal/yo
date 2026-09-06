function [cles, sommes] = dbGroupSum(t, colonneCle, colonneValeur)
%DBGROUPSUM Somme d'une colonne, groupée par une autre.
%   [CLES,SOMMES] = DBGROUPSUM(T,COLONNECLE,COLONNEVALEUR) rend une clé
%   par valeur distincte rencontrée, et la somme correspondante. C'est le
%   « GROUP BY » d'un langage de requête.
%
%   Les groupes partitionnent la table : la somme des sommes est le total
%   général. C'est la propriété qui valide tout regroupement, et elle se
%   vérifie en une ligne.
%
%   Les clés sortent dans l'ordre où elles apparaissent, non triées :
%   c'est l'ordre de la table, et il porte souvent une information.
%
%   Exemple :
%      [services, masses] = dbGroupSum(t, 'service', 'salaire');
%      sum(masses)                     % le total general
%
%   Voir aussi DBSELECT, DBTABLE.
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
