function points = bbox2points(bbox)
%BBOX2POINTS Coins d'une boîte englobante.
%   P = BBOX2POINTS([X Y L H]) rend les quatre coins, dans le sens
%   horaire depuis le coin haut-gauche : une matrice 4x2.
%
%   Exemple :
%      bbox2points([1 2 10 20])   % [1 2; 11 2; 11 22; 1 22]
    n = size(bbox, 1);
    if n == 1
        x = bbox(1); y = bbox(2); l = bbox(3); h = bbox(4);
        points = [x, y; x + l, y; x + l, y + h; x, y + h];
        return
    end
    points = zeros(4, 2, n);
    for k = 1:n
        points(:, :, k) = bbox2points(bbox(k, :));
    end
end
