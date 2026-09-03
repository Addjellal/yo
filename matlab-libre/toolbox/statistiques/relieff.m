function [rangs, poids] = relieff(X, y, k, varargin)
%RELIEFF Classement des variables par la méthode ReliefF.
%   [RANGS,POIDS] = RELIEFF(X,Y,K) classe les variables par leur pouvoir
%   discriminant. Pour chaque observation, la méthode regarde ses K plus
%   proches voisins de la même classe et ses K plus proches voisins de
%   chaque autre classe : une variable qui sépare bien varie peu entre
%   voisins de même classe et beaucoup entre voisins de classes
%   différentes.
%
%   Contrairement à un test variable par variable, ReliefF voit les
%   dépendances : une variable qui n'est utile qu'en compagnie d'une
%   autre est repérée.
%
%   RELIEFF(...,'method','regression') traite une réponse continue.
%
%   Exemple :
%      rng(1);
%      X = randn(200, 5);
%      y = double(X(:, 1) + X(:, 2) > 0) + 1;
%      rangs = relieff(X, y, 10);
%      all(ismember([1 2], rangs(1:2)))
%
%   Voir aussi SEQUENTIALFS, FITCTREE, PCA, CORR.
    X = double(X);
    y = y(:);
    if nargin < 3 || isempty(k)
        k = 10;
    end
    methode = 'classification';
    j = 1;
    while j + 1 <= numel(varargin)
        switch lower(char(varargin{j}))
            case 'method',  methode = lower(char(varargin{j+1}));
            case {'prior', 'updates', 'categoricalpredictors', 'sigma'}
                % Acceptées et sans effet.
            otherwise
                error('stats:relieff:Option', 'Option inconnue : %s.', char(varargin{j}));
        end
        j = j + 2;
    end
    [n, p] = size(X);
    etendues = max(X, [], 1) - min(X, [], 1);
    etendues(etendues == 0) = 1;
    poids = zeros(1, p);
    if strncmp(methode, 'r', 1)
        yEtendue = max(y) - min(y);
        if yEtendue == 0
            yEtendue = 1;
        end
    else
        classes = unique(y);
        frequences = zeros(numel(classes), 1);
        for c = 1:numel(classes)
            frequences(c) = mean(y == classes(c));
        end
    end
    for i = 1:n
        distances = sum(abs(X - repmat(X(i, :), n, 1)) ./ repmat(etendues, n, 1), 2);
        distances(i) = inf;
        if strncmp(methode, 'r', 1)
            [~, ordre] = sort(distances);
            voisins = ordre(1:min(k, n - 1));
            for v = voisins.'
                diffY = abs(y(i) - y(v)) / yEtendue;
                diffX = abs(X(i, :) - X(v, :)) ./ etendues;
                % En régression, une variable compte quand elle varie du
                % même côté que la réponse.
                poids = poids + (2 * diffY - 1) * diffX;
            end
            continue;
        end
        for c = 1:numel(classes)
            memeClasse = (y == classes(c));
            candidats = find(memeClasse);
            candidats(candidats == i) = [];
            if isempty(candidats)
                continue;
            end
            [~, ordre] = sort(distances(candidats));
            voisins = candidats(ordre(1:min(k, numel(candidats))));
            contribution = zeros(1, p);
            for v = voisins.'
                contribution = contribution + abs(X(i, :) - X(v, :)) ./ etendues;
            end
            contribution = contribution / numel(voisins);
            if classes(c) == y(i)
                poids = poids - contribution;
            else
                proportion = frequences(c) / max(1 - frequences(y(i) == classes), eps);
                poids = poids + proportion * contribution;
            end
        end
    end
    poids = poids / n;
    [~, rangs] = sort(poids, 'descend');
end
