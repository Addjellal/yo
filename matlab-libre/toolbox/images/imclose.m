function y = imclose(x, element)
%IMCLOSE Fermeture morphologique : dilatation puis érosion.
    if nargin < 2
        element = ones(3, 3);
    end
    y = imerode(imdilate(x, element), element);
end
