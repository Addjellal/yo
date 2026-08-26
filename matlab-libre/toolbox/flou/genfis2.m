function fis = genfis2(entrees, sorties, rayons, bornes, options)
%GENFIS2 Système de Sugeno par classification soustractive.
%   FIS = GENFIS2(X,Y,RA) cherche les centres de classes dans l'espace
%   commun des entrées et des sorties, puis fait de chaque centre une
%   règle : les prémisses sont des gaussiennes centrées sur la projection
%   du centre dans l'espace d'entrée, et la conclusion la projection dans
%   l'espace de sortie.
%
%   À la différence de GENFIS1, le nombre de règles ne croît pas
%   exponentiellement avec le nombre d'entrées : il vaut le nombre de
%   classes trouvées, que le rayon RA règle indirectement.
%
%   FIS = GENFIS2(X,Y,RA,BORNES,OPTIONS) passe les mêmes arguments que
%   SUBCLUST.
%
%   Exemple :
%      x = (0:0.1:10)';
%      fis = genfis2(x, sin(x), 0.3);
%
%   Voir aussi GENFIS1, SUBCLUST, ANFIS.
    if nargin < 3 || isempty(rayons), rayons = 0.5; end
    if nargin < 4, bornes = []; end
    if nargin < 5, options = []; end
    X = double(entrees);
    Y = double(sorties);
    if size(X, 1) ~= size(Y, 1)
        error('fuzzy:genfis2:BadData', 'X et Y doivent avoir le même nombre de lignes.');
    end
    ensemble = [X, Y];
    if isempty(bornes)
        [centres, sigmas] = subclust(ensemble, rayons, [], options);
    else
        [centres, sigmas] = subclust(ensemble, rayons, bornes, options);
    end
    nEntrees = size(X, 2);
    nSorties = size(Y, 2);
    nRegles = size(centres, 1);
    fis = newfis('genfis2', 'sugeno');
    for k = 1:nEntrees
        fis = addvar(fis, 'input', sprintf('in%d', k), [min(X(:, k)) max(X(:, k))]);
        for r = 1:nRegles
            fis = addmf(fis, 'input', k, sprintf('in%dcluster%d', k, r), 'gaussmf', ...
                        [sigmas(k), centres(r, k)]);
        end
    end
    for s = 1:nSorties
        fis = addvar(fis, 'output', sprintf('out%d', s), [min(Y(:, s)) max(Y(:, s))]);
        for r = 1:nRegles
            fis = addmf(fis, 'output', s, sprintf('out%dcluster%d', s, r), 'constant', ...
                        centres(r, nEntrees + s));
        end
    end
    regles = zeros(nRegles, nEntrees + nSorties + 2);
    for r = 1:nRegles
        regles(r, :) = [repmat(r, 1, nEntrees), repmat(r, 1, nSorties), 1, 1];
    end
    fis = addrule(fis, regles);
end
