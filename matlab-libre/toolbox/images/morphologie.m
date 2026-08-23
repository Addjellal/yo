function y = morphologie(x, element, operation)
%MORPHOLOGIE Noyau commun de l'érosion et de la dilatation.
%   Hors de l'image, le voisinage vaut l'élément neutre de l'opération :
%   plus l'infini pour l'érosion, moins l'infini pour la dilatation. Un
%   pixel dont tout le voisinage sort du cadre garde donc sa valeur
%   neutre, au lieu de faire échouer le calcul sur un ensemble vide.
    x = double(x);
    [h, l] = size(x);
    [he, le] = size(element);
    di = floor(he / 2);
    dj = floor(le / 2);
    erosion = strcmp(operation, 'min');
    if erosion
        neutre = Inf;
    else
        neutre = -Inf;
    end
    y = zeros(h, l);
    for i = 1:h
        for j = 1:l
            v = neutre;
            for a = 1:he
                for b = 1:le
                    if element(a, b) == 0
                        continue
                    end
                    ii = i + a - di - 1;
                    jj = j + b - dj - 1;
                    if ii >= 1 && ii <= h && jj >= 1 && jj <= l
                        if erosion
                            v = min(v, x(ii, jj));
                        else
                            v = max(v, x(ii, jj));
                        end
                    end
                end
            end
            y(i, j) = v;
        end
    end
end
