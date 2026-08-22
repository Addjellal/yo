function y = imerode(x, element)
%IMERODE Érosion morphologique.
    if nargin < 2
        element = ones(3, 3);
    end
    y = morphologie(x, element, 'min');
end
