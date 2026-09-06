function bw = imextendedmin(image, h, connexite)
%IMEXTENDEDMIN Minima étendus : les cuvettes d'au moins H de profondeur.
%   BW = IMEXTENDEDMIN(X,H) marque les régions qui sont des minima
%   régionaux de la surface une fois comblée de H.
%
%   « Étendu » veut dire qu'un plateau entier est marqué, non un seul
%   pixel : un minimum régional n'est pas forcément ponctuel, et ne
%   retenir qu'un point y serait arbitraire.
%
%   Exemple :
%      relief = ones(20); relief(5, 5) = 0.9; relief(15, 15) = 0.2;
%      profonds = imextendedmin(relief, 0.5);
%      profonds(15, 15) && ~profonds(5, 5)     % true
%
%   Voir aussi IMEXTENDEDMAX, IMHMIN, WATERSHED.
    if nargin < 3 || isempty(connexite), connexite = 8; end
    bw = imregionalmin(imhmin(image, h, connexite), connexite);
end
