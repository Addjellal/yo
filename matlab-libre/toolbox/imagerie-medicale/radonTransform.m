function [sinogramme, angles] = radonTransform(image, angles)
%RADONTRANSFORM Projections de l'image pour une série d'angles.
    if nargin < 2
        angles = 0:179;
    end
    [h, l] = size(image);
    diagonale = ceil(sqrt(h^2 + l^2));
    sinogramme = zeros(diagonale, numel(angles));
    ci = (h + 1) / 2;
    cj = (l + 1) / 2;
    centre = (diagonale + 1) / 2;
    for a = 1:numel(angles)
        t = angles(a) * pi / 180;
        for i = 1:h
            for j = 1:l
                if image(i, j) == 0
                    continue;
                end
                x = j - cj;
                y = ci - i;
                s = round(x * cos(t) + y * sin(t) + centre);
                if s >= 1 && s <= diagonale
                    sinogramme(s, a) = sinogramme(s, a) + image(i, j);
                end
            end
        end
    end
end
