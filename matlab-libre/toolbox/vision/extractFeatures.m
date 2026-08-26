function [descripteurs, positionsValides] = extractFeatures(I, positions, taille)
%EXTRACTFEATURES Descripteurs par imagette normalisée autour de chaque point.
%   [D,P] = EXTRACTFEATURES(I,POSITIONS) rend une ligne de descripteur par
%   point retenu : le voisinage centré, centré-réduit puis mis à plat.
    if nargin < 3
        taille = 5;
    end
    I = double(I);
    if ndims(I) == 3
        I = rgb2gray(I);
    end
    r = floor(taille / 2);
    [h, l] = size(I);
    descripteurs = [];
    positionsValides = [];
    for k = 1:size(positions, 1)
        j = round(positions(k, 1));
        i = round(positions(k, 2));
        if i - r < 1 || i + r > h || j - r < 1 || j + r > l
            continue;
        end
        bloc = I(i-r:i+r, j-r:j+r);
        v = bloc(:).';
        v = v - mean(v);
        n = norm(v);
        if n > 0
            v = v / n;
        end
        descripteurs(end+1, :) = v;
        positionsValides(end+1, :) = [j i];
    end
end
