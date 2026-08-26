function [etiquettes, nombre] = bwlabeln(bw, connexite)
%BWLABELN Étiquetage des composantes connexes, connexité quelconque.
%   Sur une image bidimensionnelle, CONNEXITE peut valoir 4, 8 ou un
%   tableau logique 3 x 3.
    if nargin < 2 || isempty(connexite), connexite = 8; end
    bw = logical(bw);
    if numel(connexite) == 1
        [etiquettes, nombre] = bwlabel(bw, connexite);
        return
    end
    decalages = voisinageConnexite(connexite);
    [h, l] = size(bw);
    etiquettes = zeros(h, l);
    nombre = 0;
    for i = 1:h
        for j = 1:l
            if ~bw(i, j) || etiquettes(i, j) > 0
                continue
            end
            nombre = nombre + 1;
            pile = [i j];
            etiquettes(i, j) = nombre;
            while ~isempty(pile)
                courant = pile(end, :);
                pile(end, :) = [];
                for k = 1:size(decalages, 1)
                    ii = courant(1) + decalages(k, 1);
                    jj = courant(2) + decalages(k, 2);
                    if ii >= 1 && ii <= h && jj >= 1 && jj <= l && ...
                            bw(ii, jj) && etiquettes(ii, jj) == 0
                        etiquettes(ii, jj) = nombre;
                        pile(end + 1, :) = [ii jj];      %#ok<AGROW>
                    end
                end
            end
        end
    end
end
