function partition = cvpartition(n, methode, parametre)
%CVPARTITION Découpage d'un jeu de données pour la validation croisée.
%   P = CVPARTITION(N,'HoldOut',F) réserve une fraction F pour le test.
%   P = CVPARTITION(N,'KFold',K) découpe en K blocs.
    if nargin < 2
        methode = 'KFold';
    end
    if nargin < 3
        parametre = 10;
    end
    ordre = randperm(n);
    switch lower(char(methode))
        case 'holdout'
            nTest = max(1, round(parametre * n));
            test = false(n, 1);
            test(ordre(1:nTest)) = true;
            partition = struct('type', 'holdout', 'N', n, 'test', test, ...
                               'training', ~test, 'NumTestSets', 1);
        otherwise
            k = parametre;
            bloc = zeros(n, 1);
            for i = 1:n
                bloc(ordre(i)) = mod(i - 1, k) + 1;
            end
            partition = struct('type', 'kfold', 'N', n, 'fold', bloc, ...
                               'NumTestSets', k);
    end
end
