function sys = zpk(z, p, k, Ts)
%ZPK Modèle par zéros, pôles et gain.
%   SYS = ZPK(Z,P,K) construit la fonction de transfert correspondante.
    if nargin < 4
        Ts = 0;
    end
    num = k * poly(z);
    den = poly(p);
    sys = tf(num, den, Ts);
end
