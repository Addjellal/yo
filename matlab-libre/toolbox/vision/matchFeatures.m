function paires = matchFeatures(d1, d2, varargin)
%MATCHFEATURES Appariement de descripteurs par plus proche voisin.
%   PAIRES = MATCHFEATURES(D1,D2) rend les couples d'indices appariés. Le
%   test du rapport des deux meilleures distances (0.7) élimine les
%   appariements ambigus.
    rapportMax = 0.7;
    for k = 1:2:numel(varargin)-1
        if strcmpi(char(varargin{k}), 'maxratio')
            rapportMax = varargin{k+1};
        end
    end
    paires = [];
    for i = 1:size(d1, 1)
        distances = zeros(size(d2, 1), 1);
        for j = 1:size(d2, 1)
            distances(j) = norm(d1(i, :) - d2(j, :));
        end
        [trie, ordre] = sort(distances);
        if numel(trie) == 1 || (trie(1) < rapportMax * trie(2))
            paires(end+1, :) = [i ordre(1)];
        end
    end
end
