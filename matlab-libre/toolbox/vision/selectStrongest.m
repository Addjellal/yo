function [choisis, indices] = selectStrongest(points, metrique, n)
%SELECTSTRONGEST Garde les N points les plus forts.
%   [P,IDX] = SELECTSTRONGEST(POINTS,METRIQUE,N) trie par métrique
%   décroissante et garde les N premiers.
%
%   Exemple :
%      [choisis, indices] = selectStrongest([1 1; 2 2; 3 3], [0.1; 0.9; 0.5], 2);
%      indices'                    % 2 3 : les deux plus fortes reponses
    [~, ordre] = sort(metrique(:), 'descend');
    n = min(n, numel(ordre));
    indices = ordre(1:n);
    choisis = points(indices, :);
end
