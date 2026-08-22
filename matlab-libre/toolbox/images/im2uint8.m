function y = im2uint8(x)
%IM2UINT8 Convertit une image en uint8 (0 à 255).
    if isa(x, 'uint8')
        y = x;
    elseif islogical(x)
        y = uint8(x) * 255;
    else
        y = uint8(round(max(0, min(1, double(x))) * 255));
    end
end
