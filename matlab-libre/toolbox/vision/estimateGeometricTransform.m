function T = estimateGeometricTransform(points1, points2, genre)
%ESTIMATEGEOMETRICTRANSFORM Transformation entre deux jeux de points.
%   T = ESTIMATEGEOMETRICTRANSFORM(P1,P2,'affine') rend la matrice 3x3 qui
%   envoie P1 sur P2 au sens des moindres carrés.
    if nargin < 3
        genre = 'affine';
    end
    n = size(points1, 1);
    A = [points1, ones(n, 1)];
    switch lower(char(genre))
        case 'similarity'
            % Rotation, échelle et translation.
            c1 = mean(points1, 1);
            c2 = mean(points2, 1);
            p = points1 - repmat(c1, n, 1);
            q = points2 - repmat(c2, n, 1);
            H = p.' * q;
            [U, ~, V] = svd(H);
            R = V * U.';
            echelle = sum(sum(q .* (p * R.'))) / max(sum(sum(p .^ 2)), eps);
            t = c2.' - echelle * R * c1.';
            T = [echelle * R, t; 0 0 1];
        otherwise
            X = A \ points2;
            T = [X.'; 0 0 1];
    end
end
