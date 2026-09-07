function [b, indices] = mink(a, k, dim)
%MINK Les K plus petits éléments.
%   B = MINK(A,K) rend les K plus petits éléments, en ordre croissant.
%   Pour une matrice, l'opération se fait colonne par colonne.
%   B = MINK(A,K,DIM) opère le long de la dimension DIM.
%   [B,I] = MINK(...) rend en outre leurs indices.
%
%   Exemple :
%      mink([3 1 4 1 5], 2)                % 1 1
%      [b, i] = mink([3 1 4 1 5], 2);
%      i                                   % 2 4
%      isequal(mink([3 1 4], 3), sort([3 1 4]))     % 1
%
%   Voir aussi MAXK, SORT, TOPKROWS, MIN.
    if nargin < 3
        if isvector(a), dim = find(size(a) > 1, 1); else, dim = 1; end
        if isempty(dim), dim = 1; end
    end
    [trie, ordre] = sort(a, dim, 'ascend');
    k = min(round(k), size(a, dim));
    indexeur = repmat({':'}, 1, max(ndims(a), dim));
    indexeur{dim} = 1:k;
    b = trie(indexeur{:});
    indices = ordre(indexeur{:});
end
