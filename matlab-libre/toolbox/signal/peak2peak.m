function r = peak2peak(x, dim)
%PEAK2PEAK Écart entre le maximum et le minimum.
%   Exemple :  peak2peak([1 5 2])   % 4
    if nargin < 2
        if isvector(x), r = max(x) - min(x); return, end
        dim = 1;
    end
    r = max(x, [], dim) - min(x, [], dim);
end
