function y = medfilt2(x, taille)
%MEDFILT2 Filtre médian bidimensionnel.
%   Y = MEDFILT2(X,[M N]) remplace chaque pixel par la médiane de son
%   voisinage, de taille 3 sur 3 par défaut.
%
%   La médiane n'est pas une moyenne : elle efface complètement un point
%   isolé aberrant, là où la moyenne l'étale sur tout le voisinage. C'est
%   pourquoi elle est le remède au bruit poivre et sel, et pourquoi elle
%   conserve les contours francs qu'un lissage gaussien émousserait.
%
%   Elle n'est pas linéaire : la médiane d'une somme n'est pas la somme
%   des médianes, et aucune analyse en fréquence ne la décrit.
%
%   Exemple :
%      image = ones(9); image(5, 5) = 100;
%      medfilt2(image)(5, 5)           % 1 : l'aberrant a disparu
%
%   Voir aussi IMGAUSSFILT, IMFILTER, MEDIAN.
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
