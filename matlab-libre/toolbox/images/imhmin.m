function sortie = imhmin(image, h, connexite)
%IMHMIN Comble les minima de profondeur inférieure à H.
    if nargin < 3 || isempty(connexite), connexite = 8; end
    sortie = -imhmax(-double(image), h, connexite);
end
