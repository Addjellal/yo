function cellules = matlibre_rob_bresenham(a, b)
%MATLIBRE_ROB_BRESENHAM Cellules d'une grille traversées par un segment.
%   CELLULES = MATLIBRE_ROB_BRESENHAM([I1 J1],[I2 J2]) rend la suite des
%   indices, extrémités comprises.
%
%   L'algorithme n'emploie que des entiers : c'est ce qui le rend exact,
%   là où un pas en flottant finirait par sauter une cellule ou en
%   compter deux.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
    i = round(a(1)); j = round(a(2));
    i2 = round(b(1)); j2 = round(b(2));
    di = abs(i2 - i);
    dj = abs(j2 - j);
    si = sign(i2 - i);
    sj = sign(j2 - j);
    erreur = di - dj;
    cellules = zeros(di + dj + 1, 2);
    n = 0;
    while true
        n = n + 1;
        cellules(n, :) = [i, j];
        if i == i2 && j == j2
            break
        end
        deux = 2 * erreur;
        if deux > -dj
            erreur = erreur - dj;
            i = i + si;
        end
        if deux < di
            erreur = erreur + di;
            j = j + sj;
        end
    end
    cellules = cellules(1:n, :);
end
