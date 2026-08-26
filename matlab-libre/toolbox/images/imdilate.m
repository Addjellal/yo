function y = imdilate(x, element)
%IMDILATE Dilatation morphologique.
    if nargin < 2
        element = ones(3, 3);
    end
    y = morphologie(x, element, 'max');
end
