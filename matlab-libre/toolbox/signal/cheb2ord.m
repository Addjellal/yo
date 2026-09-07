function [n, Wn] = cheb2ord(Wp, Ws, Rp, Rs)
%CHEB2ORD Ordre minimal d'un filtre de Chebyshev de type II.
%   WN vaut WS : c'est la bande atténuée qui est fixée.
%
%   Exemple :
%      [n, Wn] = cheb2ord(0.2, 0.3, 1, 40);
%      n
    [n, ~] = cheb1ord(Wp, Ws, Rp, Rs);
    Wn = Ws;
end
