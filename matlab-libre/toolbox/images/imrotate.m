function y = imrotate(x, angle)
%IMROTATE Rotation d'une image, en degrés, autour de son centre.
    [h, l] = size(x);
    t = angle * pi / 180;
    c = cos(t); s = sin(t);
    ci = (h + 1) / 2; cj = (l + 1) / 2;
    y = zeros(h, l);
    for i = 1:h
        for j = 1:l
            di = i - ci; dj = j - cj;
            si = ci + c * di + s * dj;
            sj = cj - s * di + c * dj;
            i0 = round(si); j0 = round(sj);
            if i0 >= 1 && i0 <= h && j0 >= 1 && j0 <= l
                y(i, j) = x(i0, j0);
            end
        end
    end
end
