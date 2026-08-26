function modele = fitcknn(X, y, varargin)
%FITCKNN Classifieur par k plus proches voisins.
%   M = FITCKNN(X,Y) mémorise les données ; utiliser PREDICTKNN pour
%   classer de nouvelles observations.
    k = 1;
    for i = 1:2:numel(varargin)-1
        if strcmpi(char(varargin{i}), 'numneighbors')
            k = varargin{i+1};
        end
    end
    modele = struct('type', 'knn', 'X', X, 'Y', y(:), 'K', k);
end
