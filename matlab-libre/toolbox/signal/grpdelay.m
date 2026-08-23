function [gd, w] = grpdelay(b, a, n, fs)
%GRPDELAY Temps de propagation de groupe d'un filtre numérique.
%   [GD,W] = GRPDELAY(B,A,N) rend le retard de groupe, en échantillons,
%   sur N points entre 0 et pi.
%
%   Le retard est -d(arg H)/dw ; il se calcule ici par la formule exacte
%   Re{ (B'(w)/B(w)) - (A'(w)/A(w)) }, où les dérivées viennent de la
%   pondération des coefficients par leur indice.
    if nargin < 2 || isempty(a), a = 1; end
    if nargin < 3 || isempty(n), n = 512; end
    b = b(:).';
    a = a(:).';
    w = (0:n-1)' * pi / n;
    z = exp(-1i * w);
    gd = zeros(n, 1);
    for k = 1:n
        num = polyvalDescendant(b, z(k));
        den = polyvalDescendant(a, z(k));
        numPondere = polyvalDescendant(b .* (0:numel(b)-1), z(k));
        denPondere = polyvalDescendant(a .* (0:numel(a)-1), z(k));
        if abs(num) < eps, num = eps; end
        if abs(den) < eps, den = eps; end
        gd(k) = real(numPondere / num - denPondere / den);
    end
    if nargin >= 4 && ~isempty(fs)
        w = w * fs / (2 * pi);
    end
end

function v = polyvalDescendant(c, z)
    v = 0;
    for k = 1:numel(c)
        v = v + c(k) * z^(k - 1);
    end
end
