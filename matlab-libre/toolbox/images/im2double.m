function y = im2double(x)
%IM2DOUBLE Convertit une image en double dans [0,1].
    if isa(x, 'uint8')
        y = double(x) / 255;
    elseif isa(x, 'uint16')
        y = double(x) / 65535;
    elseif islogical(x)
        y = double(x);
    else
        y = double(x);
    end
end
