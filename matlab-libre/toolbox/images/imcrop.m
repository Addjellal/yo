function y = imcrop(x, rectangle)
%IMCROP Découpe un rectangle [x y largeur hauteur] dans une image.
    j0 = max(1, round(rectangle(1)));
    i0 = max(1, round(rectangle(2)));
    j1 = min(size(x, 2), j0 + round(rectangle(3)) - 1);
    i1 = min(size(x, 1), i0 + round(rectangle(4)) - 1);
    y = x(i0:i1, j0:j1);
end
