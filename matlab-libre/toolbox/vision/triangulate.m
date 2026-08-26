function [points3D, erreurs] = triangulate(points1, points2, matrice1, matrice2)
%TRIANGULATE Reconstruction de points par intersection de rayons.
%   P = TRIANGULATE(P1,P2,M1,M2) rend les coordonnées trois dimensions des
%   points vus en P1 dans la première caméra et en P2 dans la seconde, les
%   matrices de projection étant M1 et M2.
%
%   Chaque correspondance donne quatre équations linéaires homogènes en
%   les quatre coordonnées homogènes du point : la solution est le vecteur
%   singulier associé à la plus petite valeur singulière. Deux rayons ne
%   se coupent jamais exactement en présence de bruit ; cette solution est
%   celle qui minimise l'erreur algébrique.
%
%   Les matrices sont acceptées en 3x4, convention usuelle, ou en 4x3,
%   convention de MATLAB, auquel cas elles sont transposées.
%
%   [P,E] = TRIANGULATE(...) rend aussi l'erreur de reprojection moyenne
%   de chaque point, en pixels.
%
%   Exemple :
%      M1 = [eye(3), zeros(3,1)];
%      M2 = [eye(3), [-1;0;0]];
%      triangulate([0 0], [-1 0], M1, M2)   % [0 0 1]
%
%   Voir aussi ESTIMATEFUNDAMENTALMATRIX, EPIPOLARLINE.
    M1 = normaliserMatrice(matrice1);
    M2 = normaliserMatrice(matrice2);
    P1 = double(points1);
    P2 = double(points2);
    n = size(P1, 1);
    points3D = zeros(n, 3);
    erreurs = zeros(n, 1);
    for k = 1:n
        A = [P1(k, 1) * M1(3, :) - M1(1, :);
             P1(k, 2) * M1(3, :) - M1(2, :);
             P2(k, 1) * M2(3, :) - M2(1, :);
             P2(k, 2) * M2(3, :) - M2(2, :)];
        [~, ~, V] = svd(A);
        X = V(:, end);
        if abs(X(4)) < eps
            points3D(k, :) = [NaN NaN NaN];
            erreurs(k) = Inf;
            continue
        end
        X = X / X(4);
        points3D(k, :) = X(1:3)';
        erreurs(k) = (reprojeter(M1, X, P1(k, :)) + reprojeter(M2, X, P2(k, :))) / 2;
    end
end

function M = normaliserMatrice(M)
    M = double(M);
    if isequal(size(M), [4 3])
        M = M';
    end
    if ~isequal(size(M), [3 4])
        error('vision:triangulate:BadMatrix', ...
              'La matrice de projection doit être 3x4 ou 4x3.');
    end
end

function e = reprojeter(M, X, mesure)
    p = M * X;
    if abs(p(3)) < eps
        e = Inf;
        return
    end
    e = norm(p(1:2)' / p(3) - mesure);
end
