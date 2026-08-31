function [dissemblance, Z, transformation] = procrustes(X, Y, varargin)
%PROCRUSTES Superposition de deux nuages de points.
%   D = PROCRUSTES(X,Y) cherche la rotation, la mise à l'échelle et la
%   translation qui rapprochent le plus le nuage Y du nuage X, et rend la
%   dissemblance qui subsiste : la somme des carrés des écarts, rapportée
%   à la dispersion de X. Elle vaut 0 quand les deux nuages sont
%   superposables, 1 quand Y n'apporte rien de plus qu'un point unique.
%
%   Les deux nuages doivent avoir le même nombre de points, et le
%   i-ième point de l'un correspond au i-ième de l'autre.
%
%   [D,Z] = PROCRUSTES(X,Y) rend le nuage Y transformé, celui qui se
%   superpose à X.
%
%   [D,Z,T] = PROCRUSTES(X,Y) rend la transformation, dans une structure
%   de trois champs : T.c la translation, T.T la rotation, T.b l'échelle,
%   telles que Z = T.b * Y * T.T + T.c.
%
%   PROCRUSTES(...,'Scaling',false) interdit la mise à l'échelle : la
%   transformation se réduit à une rotation et une translation.
%   PROCRUSTES(...,'Reflection',false) interdit la réflexion : la
%   rotation garde l'orientation. 'best' laisse choisir celle qui
%   rapproche le plus, ce qui est le défaut.
%
%   C'est l'outil de la morphométrie et de la comparaison de
%   configurations : il répond à « ces deux formes sont-elles les mêmes,
%   à la position, l'orientation et la taille près ? »
%
%   Exemples :
%      X = [0 0; 1 0; 1 1; 0 1];
%      Y = X * [0 1; -1 0] * 3 + 5;      % tourne, agrandi, deplace
%      [d, Z] = procrustes(X, Y);
%      d                                  % pratiquement zero
%      max(max(abs(Z - X)))               % Z retombe sur X
%
%   Voir aussi PDIST, MDSCALE, PCA, CANONCORR, SVD.
    echelleAutorisee = true;
    reflexion = 'best';
    k = 1;
    while k + 1 <= numel(varargin)
        nom = lower(char(varargin{k}));
        if strcmp(nom, 'scaling')
            echelleAutorisee = logical(varargin{k + 1});
        elseif strcmp(nom, 'reflection')
            reflexion = varargin{k + 1};
        else
            error('stats:procrustes:BadOption', 'Unknown option ''%s''.', nom);
        end
        k = k + 2;
    end
    [n, p] = size(X);
    if size(Y, 1) ~= n
        error('stats:procrustes:InputSizeMismatch', ...
              'X and Y must have the same number of rows.');
    end
    q = size(Y, 2);
    % Si Y a moins de colonnes que X, on le complète de zéros : la
    % superposition d'un nuage plan sur un nuage de l'espace a un sens.
    if q < p
        Y = [Y, zeros(n, p - q)];
    elseif q > p
        X = [X, zeros(n, q - p)];
        p = q;
    end
    centreX = mean(X, 1);
    centreY = mean(Y, 1);
    A = X - repmat(centreX, n, 1);
    B = Y - repmat(centreY, n, 1);
    normeA = sqrt(sum(A(:) .^ 2));
    normeB = sqrt(sum(B(:) .^ 2));
    if normeA == 0 || normeB == 0
        dissemblance = 1;
        Z = repmat(centreX, n, 1);
        transformation = struct('T', eye(p), 'b', 0, 'c', repmat(centreX, n, 1));
        return;
    end
    A = A / normeA;
    B = B / normeB;
    [U, S, V] = svd(B' * A);
    T = U * V';
    if ~(ischar(reflexion) || isstring(reflexion))
        % Réflexion imposée : on force le signe du déterminant.
        voulu = 1;
        if ~reflexion
            voulu = 1;
        end
        if det(T) * voulu < 0
            V(:, end) = -V(:, end);
            S(end, end) = -S(end, end);
            T = U * V';
        end
    end
    trace_ = sum(diag(S));
    if echelleAutorisee
        b = trace_ * normeA / normeB;
        dissemblance = 1 - trace_ ^ 2;
        Z = normeA * trace_ * B * T + repmat(centreX, n, 1);
    else
        b = 1;
        dissemblance = 1 + (normeB / normeA) ^ 2 - 2 * trace_ * normeB / normeA;
        Z = normeB * B * T + repmat(centreX, n, 1);
    end
    dissemblance = max(0, dissemblance);
    c = repmat(centreX, n, 1) - b * repmat(centreY, n, 1) * T;
    transformation = struct('T', T, 'b', b, 'c', c);
end
