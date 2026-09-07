function bw = imregionalmin(image, connexite)
%IMREGIONALMIN Minima régionaux d'une image.
%   Dual d'IMREGIONALMAX, appliqué à l'image inversée.
%
%   Exemple :
%      x = [3 3 3; 3 1 3; 3 3 3];
%      sum(sum(imregionalmin(x)))  % 1 : un seul minimum regional
%
%   Voir aussi IMREGIONALMAX, IMIMPOSEMIN, WATERSHED.
    if nargin < 2 || isempty(connexite), connexite = 8; end
    bw = imregionalmax(-double(image), connexite);
end
