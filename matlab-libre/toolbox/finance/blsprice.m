function [call, put] = blsprice(S, K, r, T, sigma, q)
%BLSPRICE Prix d'options européennes par la formule de Black-Scholes.
%   [C,P] = BLSPRICE(S,K,R,T,SIGMA) rend les prix de l'achat et de la
%   vente. Q est le taux de dividende continu (zéro par défaut).
%
%   Exemple :
%      [c, p] = blsprice(100, 100, 0.05, 1, 0.2);
%      abs(c - p - (100 - 100 * exp(-0.05))) < 1e-9   % la parite achat-vente
%
%   Voir aussi BLSDELTA, BLSGAMMA, BLSVEGA, BLSIMPV.
    if nargin < 6
        q = 0;
    end
    d1 = (log(S ./ K) + (r - q + sigma .^ 2 / 2) .* T) ./ (sigma .* sqrt(T));
    d2 = d1 - sigma .* sqrt(T);
    N = @(x) 0.5 * erfc(-x / sqrt(2));
    call = S .* exp(-q * T) .* N(d1) - K .* exp(-r * T) .* N(d2);
    put = K .* exp(-r * T) .* N(-d2) - S .* exp(-q * T) .* N(-d1);
end
