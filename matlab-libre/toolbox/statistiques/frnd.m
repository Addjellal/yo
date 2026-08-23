function r = frnd(v1, v2, varargin)
%FRND Tirages d'une loi de Fisher-Snedecor.
%   Le rapport de deux khi-deux réduits suit la loi F.
    forme = statForme(size(v1 + v2), varargin);
    v1 = statEtendre(v1, forme);
    v2 = statEtendre(v2, forme);
    r = (chi2rnd(v1) ./ v1) ./ (chi2rnd(v2) ./ v2);
    r(v1 <= 0 | v2 <= 0) = NaN;
end
