function sys = parallel(sys1, sys2)
%PARALLEL Mise en parallèle de deux modèles (somme des sorties).
    a = tf(sys1);
    b = tf(sys2);
    num = polyadd(conv(a.num, b.den), conv(b.num, a.den));
    den = conv(a.den, b.den);
    sys = tf(num, den, max(a.Ts, b.Ts));
end

function s = polyadd(p, q)
    n = max(numel(p), numel(q));
    p = [zeros(1, n - numel(p)), p];
    q = [zeros(1, n - numel(q)), q];
    s = p + q;
end
