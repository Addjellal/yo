function e = immse(a, b)
%IMMSE Erreur quadratique moyenne entre deux images.
    a = double(a);
    b = double(b);
    d = a(:) - b(:);
    e = sum(d.^2) / numel(d);
end
