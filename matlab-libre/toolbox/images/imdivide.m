function r = imdivide(a, b)
%IMDIVIDE Quotient terme à terme de deux images.
    if isinteger(a)
        r = cast(double(a) ./ double(b), class(a));
    else
        r = double(a) ./ double(b);
    end
end
