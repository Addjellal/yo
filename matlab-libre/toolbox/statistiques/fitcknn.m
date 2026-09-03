function modele = fitcknn(X, y, varargin)
%FITCKNN Classifieur par k plus proches voisins.
%   M = FITCKNN(X,Y) mémorise les données ; PREDICT classe ensuite de
%   nouvelles observations. Il n'y a rien à apprendre : la règle est de
%   regarder les K voisins les plus proches, et le modèle n'est que les
%   données elles-mêmes.
%
%   Exemple :
%      X = [randn(30, 2); randn(30, 2) + 3];
%      y = [ones(30, 1); 2 * ones(30, 1)];
%      m = fitcknn(X, y, 'NumNeighbors', 3);
%      mean(predict(m, X) == y)
%
%   Voir aussi PREDICT, FITCTREE, FITCNB, FITCSVM, KNNSEARCH.
    k = 1;
    for i = 1:2:numel(varargin)-1
        if strcmpi(char(varargin{i}), 'numneighbors')
            k = varargin{i+1};
        end
    end
    modele = struct('type', 'knn', 'X', X, 'Y', y(:), 'K', k);
end
