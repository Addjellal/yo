function r = imadd(a, b)
%IMADD Somme de deux images, avec saturation pour les entiers.
    if isinteger(a)
        r = a + cast(b, class(a));
    elseif isinteger(b)
        r = cast(a, class(b)) + b;
    else
        r = double(a) + double(b);
    end
end
