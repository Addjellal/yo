function r = unidrnd(n, varargin)
%UNIDRND Tirages d'une loi uniforme discrète sur 1..N.
    forme = statForme(size(n), varargin);
    n = statEtendre(n, forme);
    r = ceil(n .* rand(forme));
    r(r < 1) = 1;
    r(n < 1 | n ~= round(n)) = NaN;
end
