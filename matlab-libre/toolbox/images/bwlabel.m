function [etiquettes, nombre] = bwlabel(bw, connexite)
%BWLABEL Étiquetage des composantes connexes d'une image binaire.
%   [L,N] = BWLABEL(BW) numérote les régions de pixels vrais.
%   CONNEXITE vaut 4 ou 8 (8 par défaut).
    if nargin < 2
        connexite = 8;
    end
    [h, l] = size(bw);
    etiquettes = zeros(h, l);
    nombre = 0;
    for i = 1:h
        for j = 1:l
            if ~bw(i, j) || etiquettes(i, j) > 0
                continue;
            end
            nombre = nombre + 1;
            pile = [i j];
            etiquettes(i, j) = nombre;
            while ~isempty(pile)
                p = pile(end, :);
                pile(end, :) = [];
                for di = -1:1
                    for dj = -1:1
                        if di == 0 && dj == 0
                            continue;
                        end
                        if connexite == 4 && abs(di) + abs(dj) > 1
                            continue;
                        end
                        a = p(1) + di;
                        b = p(2) + dj;
                        if a >= 1 && a <= h && b >= 1 && b <= l && bw(a, b) && ...
                                etiquettes(a, b) == 0
                            etiquettes(a, b) = nombre;
                            pile(end+1, :) = [a b];
                        end
                    end
                end
            end
        end
    end
end
