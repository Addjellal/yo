function [indices, distances] = knnsearch(X, Y, varargin)
%KNNSEARCH Plus proches voisins par recherche exhaustive.
%   [IDX,D] = KNNSEARCH(X,Y) trouve, pour chaque ligne de Y, la ligne de X
%   la plus proche. Option 'K' pour en demander plusieurs.
    k = 1;
    for i = 1:2:numel(varargin)-1
        if strcmpi(char(varargin{i}), 'k')
            k = varargin{i+1};
        end
    end
    m = size(Y, 1);
    indices = zeros(m, k);
    distances = zeros(m, k);
    for i = 1:m
        d = zeros(size(X, 1), 1);
        for j = 1:size(X, 1)
            d(j) = sqrt(sum((X(j, :) - Y(i, :)) .^ 2));
        end
        [trie, ordre] = sort(d);
        indices(i, :) = ordre(1:k).';
        distances(i, :) = trie(1:k).';
    end
end
