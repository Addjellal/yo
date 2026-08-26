function bw = imextendedmin(image, h, connexite)
%IMEXTENDEDMIN Minima étendus : les cuvettes d'au moins H de profondeur.
    if nargin < 3 || isempty(connexite), connexite = 8; end
    bw = imregionalmin(imhmin(image, h, connexite), connexite);
end
