function r = immultiply(a, b)
%IMMULTIPLY Produit terme à terme de deux images.
    if isinteger(a)
        r = cast(double(a) .* double(b), class(a));
    elseif isinteger(b)
        r = cast(double(a) .* double(b), class(b));
    else
        r = double(a) .* double(b);
    end
end
