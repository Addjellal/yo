function [c, distances] = cophenet(Z, Y)
%COPHENET Corrélation cophénétique : l'arbre est-il fidèle aux distances ?
%   C = COPHENET(Z,Y) compare l'arbre Z que rend LINKAGE aux distances Y
%   que rend PDIST. Pour chaque paire d'observations, la distance
%   cophénétique est la hauteur à laquelle l'arbre les réunit ; C est la
%   corrélation entre ces hauteurs et les distances vraies.
%
%   C vaut au plus 1. Une valeur proche de 1 dit que l'arbre représente
%   fidèlement les distances ; une valeur basse, que le regroupement les
%   a beaucoup déformées. C'est le moyen usuel de choisir entre plusieurs
%   méthodes de LINKAGE sur le même jeu de données.
%
%   [C,D] = COPHENET(Z,Y) rend en outre le vecteur D des distances
%   cophénétiques, rangé comme celui de PDIST.
%
%   Exemples :
%      X = [1 1; 1.2 1; 5 5; 5.1 5.2];
%      Y = pdist(X);
%      cophenet(linkage(X, 'single'), Y)
%      cophenet(linkage(X, 'average'), Y)   % souvent la meilleure
%
%   Voir aussi LINKAGE, PDIST, CLUSTER, DENDROGRAM, SQUAREFORM.
    n = size(Z, 1) + 1;
    % La hauteur qui réunit deux observations : on refait les fusions, en
    % notant la hauteur pour toutes les paires que chacune crée.
    membres = cell(2 * n - 1, 1);
    for i = 1:n
        membres{i} = i;
    end
    H = zeros(n, n);
    for m = 1:n - 1
        a = membres{Z(m, 1)};
        b = membres{Z(m, 2)};
        H(a, b) = Z(m, 3);
        H(b, a) = Z(m, 3);
        membres{n + m} = [a, b];
    end
    distances = squareform(H);
    if nargin < 2 || isempty(Y)
        c = [];
        return;
    end
    y = Y(:)';
    if numel(y) ~= numel(distances)
        error('stats:cophenet:InputSizeMismatch', ...
              'Y must be the distance vector the tree was built from.');
    end
    a = distances - mean(distances);
    b = y - mean(y);
    na = sqrt(sum(a .^ 2));
    nb = sqrt(sum(b .^ 2));
    if na == 0 || nb == 0
        c = NaN;
    else
        c = sum(a .* b) / (na * nb);
    end
end
