function [sinogramme, angles] = radonTransform(image, angles)
%RADONTRANSFORM Projections de l'image pour une série d'angles.
%   [S,ANGLES] = RADONTRANSFORM(IMAGE) rend le sinogramme : une colonne
%   par angle, chacune donnant la somme des valeurs de l'image le long de
%   chaque droite de cet angle. Les angles vont de 0 à 179 degrés par
%   défaut.
%   RADONTRANSFORM(IMAGE,ANGLES) impose la liste des angles.
%   C'est RADON de MATLAB, dont les projections partagent chaque pixel en
%   quatre sous-pixels répartis entre les deux casiers les plus proches.
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
    sinogramme = radon(image, angles);
end
