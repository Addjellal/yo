function [n, Wn] = cheb2ord(Wp, Ws, Rp, Rs)
%CHEB2ORD Ordre minimal d'un filtre de Chebyshev de type II.
%   WN vaut WS : c'est la bande atténuée qui est fixée.
    [n, ~] = cheb1ord(Wp, Ws, Rp, Rs);
    Wn = Ws;
end
