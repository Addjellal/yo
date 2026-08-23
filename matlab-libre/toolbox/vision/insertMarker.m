function sortie = insertMarker(image, positions, forme, varargin)
%INSERTMARKER Dessine des marqueurs sur une image.
%   SORTIE = INSERTMARKER(I,POSITIONS,FORME) où FORME vaut 'circle',
%   'x', 'plus' ou 'square'. POSITIONS est une matrice Nx2 de [x y].
%   Options : 'Color' et 'Size'.
    if nargin < 3 || isempty(forme), forme = 'plus'; end
    couleur = [1 1 1];
    taille = 3;
    for k = 1:2:numel(varargin) - 1
        switch lower(char(varargin{k}))
            case 'color', couleur = varargin{k + 1};
            case 'size',  taille = varargin{k + 1};
        end
    end
    sortie = im2double(image);
    if size(sortie, 3) == 1
        sortie = cat(3, sortie, sortie, sortie);
    end
    [h, l, ~] = size(sortie);
    for k = 1:size(positions, 1)
        x = round(positions(k, 1));
        y = round(positions(k, 2));
        switch lower(char(forme))
            case 'plus'
                points = [(x-taille:x+taille)', repmat(y, 2*taille+1, 1);
                          repmat(x, 2*taille+1, 1), (y-taille:y+taille)'];
            case 'x'
                d = (-taille:taille)';
                points = [x + d, y + d; x + d, y - d];
            case 'square'
                d = (-taille:taille)';
                points = [x + d, repmat(y - taille, numel(d), 1);
                          x + d, repmat(y + taille, numel(d), 1);
                          repmat(x - taille, numel(d), 1), y + d;
                          repmat(x + taille, numel(d), 1), y + d];
            otherwise   % cercle
                angles = linspace(0, 2 * pi, 8 * taille + 8)';
                points = [x + taille * cos(angles), y + taille * sin(angles)];
        end
        points = round(points);
        garde = points(:, 1) >= 1 & points(:, 1) <= l & ...
                points(:, 2) >= 1 & points(:, 2) <= h;
        points = points(garde, :);
        for p = 1:size(points, 1)
            for plan = 1:3
                sortie(points(p, 2), points(p, 1), plan) = couleur(min(plan, numel(couleur)));
            end
        end
    end
end
