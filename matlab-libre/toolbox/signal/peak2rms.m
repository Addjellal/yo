function r = peak2rms(x, dim)
%PEAK2RMS Rapport entre la valeur crête et la valeur efficace.
%   Exemple :  peak2rms([1 -1 1 -1])   % 1
    if nargin < 2
        if isvector(x), r = max(abs(x)) / rms(x); return, end
        dim = 1;
    end
    r = max(abs(x), [], dim) ./ rms(x, dim);
end
