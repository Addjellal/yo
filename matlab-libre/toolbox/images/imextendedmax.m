function bw = imextendedmax(image, h, connexite)
%IMEXTENDEDMAX Maxima étendus : les sommets d'au moins H de hauteur.
%   BW = IMEXTENDEDMAX(X,H) marque les sommets qui dominent leur entourage
%   d'au moins H. C'est le dual d'IMEXTENDEDMIN, sur la surface retournée.
%
%   Exemple :
%      relief = zeros(20); relief(5, 5) = 0.1; relief(15, 15) = 0.8;
%      hauts = imextendedmax(relief, 0.5);
%      hauts(15, 15) && ~hauts(5, 5)   % true
%
%   Voir aussi IMEXTENDEDMIN, IMHMIN.
    if nargin < 3 || isempty(connexite), connexite = 8; end
    bw = imregionalmax(imhmax(image, h, connexite), connexite);
end
