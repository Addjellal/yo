function [d1, d2] = matlibre_bls_d(S, K, r, T, sigma, q)
%MATLIBRE_BLS_D Les deux arguments de la formule de Black et Scholes.
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
    d1 = (log(S ./ K) + (r - q + sigma .^ 2 / 2) .* T) ./ (sigma .* sqrt(T));
    d2 = d1 - sigma .* sqrt(T);
end
