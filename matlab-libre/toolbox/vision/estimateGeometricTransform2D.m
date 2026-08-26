function [T, valides] = estimateGeometricTransform2D(points1, points2, type, varargin)
%ESTIMATEGEOMETRICTRANSFORM2D Transformation géométrique entre deux jeux
%   de points.
%   T = ESTIMATEGEOMETRICTRANSFORM2D(P1,P2,TYPE) rend la matrice 3x3 qui
%   envoie P1 sur P2. TYPE vaut 'similarity', 'affine' ou 'projective'.
%
%   La convention est celle de MATLAB : les points sont des lignes, et la
%   transformation s'applique à droite, [x y 1] * T.
%
%   [T,VALIDES] = ESTIMATEGEOMETRICTRANSFORM2D(...,'MaxDistance',D) écarte
%   les appariements dont l'erreur de reprojection dépasse D, par tirages
%   aléatoires, et rend leur masque.
%
%   Exemple :
%      p1 = [0 0; 1 0; 0 1; 2 2];
%      p2 = p1 * 2 + 3;
%      T = estimateGeometricTransform2D(p1, p2, 'similarity');
%
%   Voir aussi ESTIMATEGEOMETRICTRANSFORM, ESTIMATEFUNDAMENTALMATRIX.
    if nargin < 3 || isempty(type), type = 'affine'; end
    distanceMax = [];
    tirages = 500;
    for k = 1:2:numel(varargin)-1
        switch lower(char(varargin{k}))
            case 'maxdistance', distanceMax = double(varargin{k+1});
            case 'maxnumtrials', tirages = double(varargin{k+1});
        end
    end
    P1 = double(points1);
    P2 = double(points2);
    n = size(P1, 1);
    minimum = minimumPoints(type);
    if n < minimum
        error('vision:estimateGeometricTransform2D:TooFewPoints', ...
              'Il faut au moins %d correspondances pour ce type.', minimum);
    end
    if isempty(distanceMax)
        T = ajuster(P1, P2, type);
        valides = true(n, 1);
        return
    end
    meilleurNombre = -1;
    T = ajuster(P1, P2, type);
    valides = true(n, 1);
    for essai = 1:tirages
        indices = randperm(n, minimum);
        candidat = ajuster(P1(indices, :), P2(indices, :), type);
        if isempty(candidat), continue, end
        distances = erreursReprojection(candidat, P1, P2);
        interieurs = distances <= distanceMax;
        if sum(interieurs) > meilleurNombre
            meilleurNombre = sum(interieurs);
            valides = interieurs;
        end
    end
    if sum(valides) >= minimum
        T = ajuster(P1(valides, :), P2(valides, :), type);
    end
end

function m = minimumPoints(type)
    switch lower(char(type))
        case 'similarity', m = 2;
        case 'affine',     m = 3;
        case 'projective', m = 4;
        otherwise
            error('vision:estimateGeometricTransform2D:BadType', ...
                  'Le type doit être ''similarity'', ''affine'' ou ''projective''.');
    end
end

function T = ajuster(P1, P2, type)
    n = size(P1, 1);
    switch lower(char(type))
        case 'similarity'
            % [x' y'] = s R [x y] + t : quatre inconnues, deux équations
            % par point.
            A = zeros(2 * n, 4);
            b = zeros(2 * n, 1);
            for k = 1:n
                x = P1(k, 1); y = P1(k, 2);
                A(2*k-1, :) = [x, -y, 1, 0];
                A(2*k,   :) = [y,  x, 0, 1];
                b(2*k-1) = P2(k, 1);
                b(2*k)   = P2(k, 2);
            end
            p = A \ b;
            T = [p(1), p(2), 0; -p(2), p(1), 0; p(3), p(4), 1];
        case 'affine'
            A = [P1, ones(n, 1)];
            M = A \ P2;
            T = [M, [0; 0; 1]];
        otherwise
            T = ajusterProjective(P1, P2);
    end
end

function T = ajusterProjective(P1, P2)
%AJUSTERPROJECTIVE Homographie par transformation linéaire directe.
    n = size(P1, 1);
    A = zeros(2 * n, 9);
    for k = 1:n
        x = P1(k, 1); y = P1(k, 2);
        u = P2(k, 1); v = P2(k, 2);
        A(2*k-1, :) = [-x, -y, -1, 0, 0, 0, u*x, u*y, u];
        A(2*k,   :) = [0, 0, 0, -x, -y, -1, v*x, v*y, v];
    end
    [~, ~, V] = svd(A);
    H = reshape(V(:, end), 3, 3)';
    if abs(H(3, 3)) > eps
        H = H / H(3, 3);
    end
    % Convention de MATLAB : les points sont des lignes, donc la matrice
    % est la transposée de l'homographie usuelle.
    T = H';
end

function d = erreursReprojection(T, P1, P2)
    n = size(P1, 1);
    h = [P1, ones(n, 1)] * T;
    projete = h(:, 1:2) ./ repmat(max(abs(h(:, 3)), eps) .* sign(h(:, 3) + (h(:, 3) == 0)), 1, 2);
    d = sqrt(sum((projete - P2) .^ 2, 2));
end
