function y = imopen(x, element)
%IMOPEN Ouverture morphologique : érosion puis dilatation.
    if nargin < 2
        element = ones(3, 3);
    end
    y = imdilate(imerode(x, element), element);
end
