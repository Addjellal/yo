function r = trnd(v, varargin)
%TRND Tirages d'une loi de Student à V degrés de liberté.
%   Le rapport d'une normale centrée réduite à la racine d'un khi-deux
%   réduit suit la loi de Student.
%
%   Exemple :
%      rng(1);
%      x = trnd(10, 1, 5000);
%      abs(mean(x)) < 0.1          % la loi de Student est centree
    forme = statForme(size(v), varargin);
    v = statEtendre(v, forme);
    r = randn(forme) ./ sqrt(chi2rnd(v) ./ v);
    r(v <= 0) = NaN;
end
