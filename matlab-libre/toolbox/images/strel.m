function s = strel(forme, parametre)
%STREL Élément structurant pour la morphologie.
%   S = STREL('square',N), STREL('rectangle',[M N]), STREL('disk',R),
%   STREL('line',LONGUEUR,ANGLE), STREL('diamond',R), STREL('arbitrary',M).
%   Le résultat est une matrice logique, directement utilisable par
%   IMDILATE, IMERODE, IMOPEN et IMCLOSE.
%
%   Exemple :
%      strel('square', 3)   % 3x3 de vrais
    if nargin < 2, parametre = 3; end
    switch lower(char(forme))
        case 'square'
            s = true(parametre);
        case 'rectangle'
            s = true(parametre(1), parametre(2));
        case 'disk'
            r = parametre;
            [x, y] = meshgrid(-r:r, -r:r);
            s = (x.^2 + y.^2) <= r^2 + r * 0.5;
        case 'diamond'
            r = parametre;
            [x, y] = meshgrid(-r:r, -r:r);
            s = (abs(x) + abs(y)) <= r;
        case 'line'
            longueur = parametre;
            s = true(1, max(1, round(longueur)));
        case 'arbitrary'
            s = logical(parametre);
        otherwise
            error('images:strel:UnknownShape', 'Unrecognized structuring element ''%s''.', forme);
    end
end
