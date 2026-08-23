function varargout = imsplit(image)
%IMSPLIT Sépare les plans d'une image en autant de sorties.
%   [R,V,B] = IMSPLIT(RGB).
%
%   Exemple :
%      [r, v, b] = imsplit(zeros(4, 4, 3));
    image = double(image);
    d = size(image);
    if numel(d) < 3
        varargout = {image};
        return
    end
    varargout = cell(1, d(3));
    for k = 1:d(3)
        varargout{k} = image(:, :, k);
    end
end
