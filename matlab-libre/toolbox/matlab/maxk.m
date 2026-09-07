function [b, indices] = maxk(a, k, dim)
%MAXK Les K plus grands éléments.
%   B = MAXK(A,K) rend les K plus grands éléments, en ordre décroissant.
%   Pour une matrice, l'opération se fait colonne par colonne.
%   B = MAXK(A,K,DIM) opère le long de la dimension DIM.
%   [B,I] = MAXK(...) rend en outre leurs indices.
%
%   Si K dépasse le nombre d'éléments, tous sont rendus.
%
%   C'est SORT suivi d'une troncature, et c'est ainsi qu'on l'écrit ici ;
%   l'intérêt du nom est de dire l'intention — on ne veut pas l'ordre
%   complet, seulement le sommet.
%
%   Exemple :
%      maxk([3 1 4 1 5], 2)                % 5 4
%      [b, i] = maxk([3 1 4 1 5], 2);
%      i                                   % 5 3
%      maxk([1 2; 3 4], 1)                 % 3 4 : par colonne
%
%   Voir aussi MINK, SORT, TOPKROWS, MAX.
    if nargin < 3
        if isvector(a), dim = find(size(a) > 1, 1); else, dim = 1; end
        if isempty(dim), dim = 1; end
    end
    [trie, ordre] = sort(a, dim, 'descend');
    k = min(round(k), size(a, dim));
    indexeur = repmat({':'}, 1, max(ndims(a), dim));
    indexeur{dim} = 1:k;
    b = trie(indexeur{:});
    indices = ordre(indexeur{:});
end
