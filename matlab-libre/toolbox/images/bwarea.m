function a = bwarea(bw)
%BWAREA Aire d'une région binaire, en pixels.
    a = sum(double(logical(bw(:))));
end
