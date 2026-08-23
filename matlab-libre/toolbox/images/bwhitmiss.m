function sortie = bwhitmiss(bw, se1, se2)
%BWHITMISS Transformation tout ou rien.
%   BWHITMISS(BW,SE1,SE2) garde les pixels dont le voisinage contient
%   SE1 dans l'objet et SE2 dans le fond. Avec un seul élément à trois
%   valeurs, 1 impose l'objet, -1 le fond, 0 laisse libre.
    bw = logical(bw);
    if nargin < 3
        intervalle = double(se1);
        se1 = intervalle == 1;
        se2 = intervalle == -1;
    end
    sortie = imerode(bw, double(se1)) & imerode(~bw, double(se2));
    sortie = logical(sortie);
end
