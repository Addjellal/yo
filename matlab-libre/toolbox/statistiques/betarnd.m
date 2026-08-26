function r = betarnd(a, b, varargin)
%BETARND Tirages d'une loi bêta.
%   Le rapport G1/(G1+G2) de deux gammas indépendantes de formes A et B
%   suit la loi bêta.
    forme = statForme(size(a + b), varargin);
    a = statEtendre(a, forme);
    b = statEtendre(b, forme);
    g1 = gamrnd(a, ones(forme));
    g2 = gamrnd(b, ones(forme));
    r = g1 ./ (g1 + g2);
    r(a <= 0 | b <= 0) = NaN;
end
