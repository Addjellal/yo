function r = geornd(p, varargin)
%GEORND Tirages d'une loi géométrique.
    forme = statForme(size(p), varargin);
    p = statEtendre(p, forme);
    r = geoinv(rand(forme), p);
    r(p <= 0 | p > 1) = NaN;
end
