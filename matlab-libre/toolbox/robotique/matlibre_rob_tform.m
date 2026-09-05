function T = matlibre_rob_tform(R)
%MATLIBRE_ROB_TFORM Matrices homogènes à partir de rotations.
%   T = MATLIBRE_ROB_TFORM(R) place chaque rotation 3x3 dans le coin
%   supérieur gauche d'une matrice 4x4, la translation restant nulle.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
    n = size(R, 3);
    T = zeros(4, 4, n);
    for k = 1:n
        T(:, :, k) = eye(4);
        T(1:3, 1:3, k) = R(:, :, k);
    end
    if n == 1
        T = T(:, :, 1);
    end
end
