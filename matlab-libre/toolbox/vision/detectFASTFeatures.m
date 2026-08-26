function positions = detectFASTFeatures(I, seuil)
%DETECTFASTFEATURES Coins FAST (cercle de Bresenham de rayon 3).
%   P = DETECTFASTFEATURES(I,SEUIL) rend les coordonnées [x y] des points
%   dont au moins neuf voisins consécutifs du cercle sont tous plus clairs
%   ou tous plus sombres que le centre, à SEUIL près.
    if nargin < 2
        seuil = 0.1;
    end
    I = double(I);
    if ndims(I) == 3
        I = rgb2gray(I);
    end
    cercle = [0 -3; 1 -3; 2 -2; 3 -1; 3 0; 3 1; 2 2; 1 3; 0 3; ...
              -1 3; -2 2; -3 1; -3 0; -3 -1; -2 -2; -1 -3];
    [h, l] = size(I);
    positions = [];
    for i = 4:h-3
        for j = 4:l-3
            centre = I(i, j);
            clair = zeros(1, 16);
            sombre = zeros(1, 16);
            for k = 1:16
                v = I(i + cercle(k, 2), j + cercle(k, 1));
                clair(k) = v > centre + seuil;
                sombre(k) = v < centre - seuil;
            end
            if consecutifs([clair clair]) >= 9 || consecutifs([sombre sombre]) >= 9
                positions(end+1, :) = [j i];
            end
        end
    end
end

function n = consecutifs(v)
    n = 0;
    courant = 0;
    for k = 1:numel(v)
        if v(k)
            courant = courant + 1;
            n = max(n, courant);
        else
            courant = 0;
        end
    end
end
