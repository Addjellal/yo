function out = nbinrnd(r, p, varargin)
%NBINRND Tirages d'une loi binomiale négative.
%   Mélange de Poisson par une gamma : c'est la représentation usuelle,
%   valable même pour un R non entier.
%
%   Exemple :
%      rng(1);
%      mean(nbinrnd(3, 0.5, 1, 10000))      % proche de 3 = r(1-p)/p
    forme = statForme(size(r + p), varargin);
    r = statEtendre(r, forme);
    p = statEtendre(p, forme);
    lambda = gamrnd(r, (1 - p) ./ p);
    out = poissrnd(lambda);
    out(r <= 0 | p <= 0 | p > 1) = NaN;
end
