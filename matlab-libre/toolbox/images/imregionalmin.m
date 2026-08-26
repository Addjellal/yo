function bw = imregionalmin(image, connexite)
%IMREGIONALMIN Minima régionaux d'une image.
%   Dual d'IMREGIONALMAX, appliqué à l'image inversée.
    if nargin < 2 || isempty(connexite), connexite = 8; end
    bw = imregionalmax(-double(image), connexite);
end
