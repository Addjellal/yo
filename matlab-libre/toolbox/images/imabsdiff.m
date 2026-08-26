function r = imabsdiff(a, b)
%IMABSDIFF Différence absolue de deux images, sans dépassement.
    if isinteger(a) || isinteger(b)
        r = cast(abs(double(a) - double(b)), class(a));
    else
        r = abs(double(a) - double(b));
    end
end
