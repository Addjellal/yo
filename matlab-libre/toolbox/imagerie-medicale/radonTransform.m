function [sinogramme, angles] = radonTransform(image, angles)
%RADONTRANSFORM Projections de l'image pour une série d'angles.
%   [S,ANGLES] = RADONTRANSFORM(IMAGE) rend le sinogramme : une colonne
%   par angle, chacune donnant la somme des valeurs de l'image le long de
%   chaque droite de cet angle. Les angles vont de 0 à 179 degrés par
%   défaut.
%   RADONTRANSFORM(IMAGE,ANGLES) impose la liste des angles.
%
%   C'est exactement ce que mesure un scanner : chaque détecteur relève
%   l'atténuation cumulée le long d'un rayon. Reconstruire l'image à
%   partir de ces sommes est le problème que résout IRADONTRANSFORM.
%
%   Le sinogramme porte bien son nom : un point isolé de l'image y trace
%   une sinusoïde, dont l'amplitude est sa distance au centre et la phase
%   son azimut.
%
%   La somme de chaque colonne est la même quel que soit l'angle — c'est
%   la masse totale de l'image, que la projection conserve. C'est la
%   vérification la plus simple d'un sinogramme.
%
%   Exemple :
%      image = zeros(64); image(28:36, 28:36) = 1;
%      s = radonTransform(image, 0:5:175);
%      sum(s(:, 1)) - sum(s(:, 10))    % 0 a l'arrondi pres
%
%   Voir aussi IRADONTRANSFORM, WINDOWLEVEL.
    if nargin < 2
        angles = 0:179;
    end
    [h, l] = size(image);
    diagonale = ceil(sqrt(h^2 + l^2));
    sinogramme = zeros(diagonale, numel(angles));
    ci = (h + 1) / 2;
    cj = (l + 1) / 2;
    centre = (diagonale + 1) / 2;
    for a = 1:numel(angles)
        t = angles(a) * pi / 180;
        for i = 1:h
            for j = 1:l
                if image(i, j) == 0
                    continue;
                end
                x = j - cj;
                y = ci - i;
                s = round(x * cos(t) + y * sin(t) + centre);
                if s >= 1 && s <= diagonale
                    sinogramme(s, a) = sinogramme(s, a) + image(i, j);
                end
            end
        end
    end
end
