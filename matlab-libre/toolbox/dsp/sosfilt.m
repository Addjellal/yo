function y = sosfilt(sos, x)
%SOSFILT Filtrage par sections du second ordre.
%   Chaque ligne de SOS vaut [b0 b1 b2 a0 a1 a2].
    y = x(:).';
    for k = 1:size(sos, 1)
        b = sos(k, 1:3);
        a = sos(k, 4:6);
        y = filter(b, a, y);
    end
    y = reshape(y, size(x));
end
