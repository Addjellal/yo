function sos = tf2sos(b, a)
%TF2SOS Fonction de transfert vers sections du second ordre.
%   Les pôles et zéros sont appariés par proximité, comme le veut l'usage.
    z = roots(b);
    p = roots(a);
    gain = b(1) / a(1);
    n = max(numel(z), numel(p));
    sections = ceil(n / 2);
    sos = zeros(max(sections, 1), 6);
    for k = 1:sections
        zk = [];
        pk = [];
        if 2*k-1 <= numel(z), zk = [zk, z(2*k-1)]; end
        if 2*k <= numel(z), zk = [zk, z(2*k)]; end
        if 2*k-1 <= numel(p), pk = [pk, p(2*k-1)]; end
        if 2*k <= numel(p), pk = [pk, p(2*k)]; end
        bs = real(poly(zk));
        as = real(poly(pk));
        bs = [bs, zeros(1, 3 - numel(bs))];
        as = [as, zeros(1, 3 - numel(as))];
        sos(k, :) = [bs, as];
    end
    sos(1, 1:3) = sos(1, 1:3) * gain;
end
