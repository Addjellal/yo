function r = trnd(v, varargin)
%TRND Tirages d'une loi de Student à V degrés de liberté.
%   Le rapport d'une normale centrée réduite à la racine d'un khi-deux
%   réduit suit la loi de Student.
    forme = statForme(size(v), varargin);
    v = statEtendre(v, forme);
    r = randn(forme) ./ sqrt(chi2rnd(v) ./ v);
    r(v <= 0) = NaN;
end
