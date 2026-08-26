function fis = genfis3(entrees, sorties, type, nClusters, options)
%GENFIS3 Système flou par c-moyennes floues.
%   FIS = GENFIS3(X,Y) partage l'espace en deux classes par FCM et en tire
%   un système de Sugeno, une règle par classe.
%   FIS = GENFIS3(X,Y,TYPE,N) choisit le type, 'sugeno' ou 'mamdani', et
%   le nombre de classes. N vaut 'auto' pour laisser FCM choisir deux
%   classes par défaut.
%   FIS = GENFIS3(X,Y,TYPE,N,OPTIONS) passe les options de FCM.
%
%   À la différence de GENFIS2, le nombre de règles est demandé plutôt que
%   déduit d'un rayon.
%
%   Exemple :
%      x = (0:0.1:10)';
%      fis = genfis3(x, sin(x), 'sugeno', 6);
%
%   Voir aussi GENFIS1, GENFIS2, FCM.
    if nargin < 3 || isempty(type), type = 'sugeno'; end
    if nargin < 4 || isempty(nClusters) || (ischar(nClusters) && strcmpi(nClusters, 'auto'))
        nClusters = 2;
    end
    if nargin < 5, options = []; end
    X = double(entrees);
    Y = double(sorties);
    ensemble = [X, Y];
    [centres, U] = fcm(ensemble, nClusters, options);
    nEntrees = size(X, 2);
    nSorties = size(Y, 2);
    nRegles = size(centres, 1);
    % Écart type de chaque classe le long de chaque axe, pondéré par les
    % appartenances : c'est ce qui donne la largeur des gaussiennes.
    sigmas = zeros(nRegles, nEntrees);
    for r = 1:nRegles
        poids = U(r, :)';
        for k = 1:nEntrees
            ecarts = (X(:, k) - centres(r, k)) .^ 2;
            sigmas(r, k) = sqrt(sum(poids .* ecarts) / max(sum(poids), eps));
            if sigmas(r, k) < eps
                sigmas(r, k) = 1;
            end
        end
    end
    fis = newfis('genfis3', lower(char(type)));
    for k = 1:nEntrees
        fis = addvar(fis, 'input', sprintf('in%d', k), [min(X(:, k)) max(X(:, k))]);
        for r = 1:nRegles
            fis = addmf(fis, 'input', k, sprintf('in%dcluster%d', k, r), 'gaussmf', ...
                        [sigmas(r, k), centres(r, k)]);
        end
    end
    for s = 1:nSorties
        fis = addvar(fis, 'output', sprintf('out%d', s), [min(Y(:, s)) max(Y(:, s))]);
        for r = 1:nRegles
            if strcmpi(char(type), 'mamdani')
                largeur = max(std(Y(:, s)), eps);
                fis = addmf(fis, 'output', s, sprintf('out%dcluster%d', s, r), 'gaussmf', ...
                            [largeur, centres(r, nEntrees + s)]);
            else
                fis = addmf(fis, 'output', s, sprintf('out%dcluster%d', s, r), 'constant', ...
                            centres(r, nEntrees + s));
            end
        end
    end
    regles = zeros(nRegles, nEntrees + nSorties + 2);
    for r = 1:nRegles
        regles(r, :) = [repmat(r, 1, nEntrees), repmat(r, 1, nSorties), 1, 1];
    end
    fis = addrule(fis, regles);
end
