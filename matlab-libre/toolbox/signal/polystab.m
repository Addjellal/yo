function b = polystab(a)
%POLYSTAB Stabilise un polynôme en repliant ses racines dans le disque.
%   B = POLYSTAB(A) remplace chaque racine de module supérieur à 1 par son
%   inverse conjugué : le module de la réponse est conservé, mais le
%   polynôme devient à phase minimale.
    a = a(:).';
    if numel(a) <= 1, b = a; return, end
    r = roots(a);
    dehors = abs(r) > 1;
    r(dehors) = 1 ./ conj(r(dehors));
    b = a(1) * real(poly(r));
end
