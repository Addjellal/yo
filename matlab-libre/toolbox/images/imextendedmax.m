function bw = imextendedmax(image, h, connexite)
%IMEXTENDEDMAX Maxima étendus : les sommets d'au moins H de hauteur.
    if nargin < 3 || isempty(connexite), connexite = 8; end
    bw = imregionalmax(imhmax(image, h, connexite), connexite);
end
