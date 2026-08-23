function [n, Wn] = cheb1ord(Wp, Ws, Rp, Rs)
%CHEB1ORD Ordre minimal d'un filtre de Chebyshev de type I.
%   [N,WN] = CHEB1ORD(WP,WS,RP,RS). WN vaut WP : la bande passante est
%   fixée par l'ondulation.
    wp = tan(pi * Wp / 2);
    ws = tan(pi * Ws / 2);
    numerateur = acosh(sqrt((10^(Rs / 10) - 1) / (10^(Rp / 10) - 1)));
    denominateur = acosh(ws / wp);
    n = ceil(numerateur / denominateur);
    Wn = Wp;
end
