function y = morphologie(x, element, operation)
%MORPHOLOGIE Noyau commun de l'érosion et de la dilatation.
    x = double(x);
    [h, l] = size(x);
    [he, le] = size(element);
    di = floor(he / 2);
    dj = floor(le / 2);
    y = zeros(h, l);
    for i = 1:h
        for j = 1:l
            valeurs = [];
            for a = 1:he
                for b = 1:le
                    if element(a, b) == 0
                        continue;
                    end
                    ii = i + a - di - 1;
                    jj = j + b - dj - 1;
                    if ii >= 1 && ii <= h && jj >= 1 && jj <= l
                        valeurs(end+1) = x(ii, jj);
                    end
                end
            end
            if strcmp(operation, 'min')
                y(i, j) = min(valeurs);
            else
                y(i, j) = max(valeurs);
            end
        end
    end
end
