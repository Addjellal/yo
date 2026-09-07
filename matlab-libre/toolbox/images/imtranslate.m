function r = imtranslate(image, decalage, varargin)
%IMTRANSLATE Décale une image d'un nombre entier de pixels.
%   R = IMTRANSLATE(I,[DX DY]) décale de DX colonnes et DY lignes ; les
%   pixels qui entrent valent zéro. Les décalages non entiers sont
%   arrondis.
%
%   Exemple :
%      r = imtranslate([1 2 3; 4 5 6; 7 8 9], [1 0]);
%      r(1, :)                     % 0 1 2 : tout a glisse d'une colonne
%
%   Voir aussi IMRESIZE, IMROTATE, PADARRAY.
    dx = round(decalage(1));
    dy = round(decalage(2));
    m = size(image, 1);
    n = size(image, 2);
    plans = size(image, 3);
    if plans > 1
        r = zeros(m, n, plans, class(image));
    else
        r = zeros(m, n, class(image));
    end
    lignesSource = max(1, 1 - dy):min(m, m - dy);
    colonnesSource = max(1, 1 - dx):min(n, n - dx);
    if isempty(lignesSource) || isempty(colonnesSource), return, end
    r(lignesSource + dy, colonnesSource + dx, :) = image(lignesSource, colonnesSource, :);
end
