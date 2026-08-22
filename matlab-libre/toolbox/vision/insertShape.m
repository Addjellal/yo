function J = insertShape(I, forme, position)
%INSERTSHAPE Dessine un rectangle ou une ligne dans une image.
%   J = INSERTSHAPE(I,'rectangle',[x y w h]) trace le contour.
%   J = INSERTSHAPE(I,'line',[x1 y1 x2 y2]) trace un segment.
    J = im2double(I);
    [h, l] = size(J);
    switch lower(char(forme))
        case 'rectangle'
            for k = 1:size(position, 1)
                x = round(position(k,1)); y = round(position(k,2));
                w = round(position(k,3)); ht = round(position(k,4));
                for j = max(1,x):min(l, x+w)
                    if y >= 1 && y <= h, J(y, j) = 1; end
                    if y+ht >= 1 && y+ht <= h, J(y+ht, j) = 1; end
                end
                for i = max(1,y):min(h, y+ht)
                    if x >= 1 && x <= l, J(i, x) = 1; end
                    if x+w >= 1 && x+w <= l, J(i, x+w) = 1; end
                end
            end
        case 'line'
            for k = 1:size(position, 1)
                x1 = position(k,1); y1 = position(k,2);
                x2 = position(k,3); y2 = position(k,4);
                n = max(abs(x2-x1), abs(y2-y1)) + 1;
                for t = 0:n
                    x = round(x1 + (x2-x1) * t / n);
                    y = round(y1 + (y2-y1) * t / n);
                    if x >= 1 && x <= l && y >= 1 && y <= h
                        J(y, x) = 1;
                    end
                end
            end
    end
end
