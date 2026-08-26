function [choisis, indices] = selectStrongest(points, metrique, n)
%SELECTSTRONGEST Garde les N points les plus forts.
%   [P,IDX] = SELECTSTRONGEST(POINTS,METRIQUE,N) trie par métrique
%   décroissante et garde les N premiers.
    [~, ordre] = sort(metrique(:), 'descend');
    n = min(n, numel(ordre));
    indices = ordre(1:n);
    choisis = points(indices, :);
end
