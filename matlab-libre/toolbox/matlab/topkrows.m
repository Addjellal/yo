function [b, indices] = topkrows(a, k, colonnes, sens)
%TOPKROWS Les K premières lignes dans l'ordre du tri.
%   B = TOPKROWS(A,K) rend les K lignes de A qui viennent en tête d'un tri
%   décroissant, colonne par colonne de gauche à droite : la première
%   colonne décide, la deuxième départage, et ainsi de suite.
%   B = TOPKROWS(A,K,COL) trie sur les colonnes données, dans cet ordre.
%   Une colonne négative se trie en ordre croissant.
%   B = TOPKROWS(A,K,COL,SENS) impose 'ascend' ou 'descend'.
%   [B,I] = TOPKROWS(...) rend en outre les rangs des lignes retenues
%   dans A.
%
%   C'est SORTROWS suivi d'une troncature, mais l'intention est autre :
%   on ne veut pas l'ordre complet, seulement le sommet. La différence
%   compte dès que le tableau est grand — K lignes sur un million ne
%   demandent pas de trier le million.
%
%   Si K dépasse le nombre de lignes, toutes sont rendues.
%
%   Exemple :
%      topkrows([3 1; 1 2; 2 3], 2)          % [3 1; 2 3]
%      topkrows([3 1; 1 2; 2 3], 2, 2)       % trie sur la deuxieme colonne
%      [b, i] = topkrows([3 1; 1 2; 2 3], 1);
%      i                                     % 1 : la premiere ligne
%
%   Voir aussi SORTROWS, SORT, MAXK, MINK.
    if nargin < 2 || isempty(k)
        k = 1;
    end
    n = size(a, 1);
    if nargin < 3 || isempty(colonnes)
        colonnes = 1:size(a, 2);
    end
    colonnes = double(colonnes(:))';
    if nargin >= 4 && ~isempty(sens) && strcmpi(char(sens), 'ascend')
        clefs = colonnes;
    else
        % Le defaut est decroissant, l'inverse de SORTROWS : c'est le
        % « top » du nom.
        clefs = -colonnes;
        if nargin >= 4 && ~isempty(sens) && strcmpi(char(sens), 'descend')
            clefs = -abs(colonnes);
        end
    end
    [~, ordre] = sortrows(a, clefs);
    k = min(round(k), n);
    indices = ordre(1:k);
    b = a(indices, :);
end
