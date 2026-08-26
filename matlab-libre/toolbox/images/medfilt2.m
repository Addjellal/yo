function y = medfilt2(x, taille)
%MEDFILT2 Filtre médian bidimensionnel.
    if nargin < 2
        taille = [3 3];
    end
    x = double(x);
    [h, l] = size(x);
    di = floor(taille(1) / 2);
    dj = floor(taille(2) / 2);
    y = zeros(h, l);
    for i = 1:h
        for j = 1:l
            a = max(1, i - di); b = min(h, i + di);
            c = max(1, j - dj); d = min(l, j + dj);
            bloc = x(a:b, c:d);
            y(i, j) = median(bloc(:));
        end
    end
end
