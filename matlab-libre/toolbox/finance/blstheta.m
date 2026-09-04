function [thetaCall, thetaPut] = blstheta(S, K, r, T, sigma, q)
%BLSTHETA Perte de valeur d'une option avec le temps.
%   [TC,TP] = BLSTHETA(S,K,R,T,SIGMA) rend la dérivée du prix par rapport
%   au temps qui passe : elle est presque toujours négative, une option
%   perdant de la valeur à mesure que l'échéance approche.
%
%   Exemple :
%      blstheta(100, 100, 0.05, 1, 0.2)
%
%   Voir aussi BLSPRICE, BLSDELTA, BLSGAMMA, BLSVEGA, BLSRHO.
    if nargin < 6, q = 0; end
    [d1, d2] = matlibre_bls_d(S, K, r, T, sigma, q);
    N = @(x) 0.5 * erfc(-x / sqrt(2));
    commun = -S .* exp(-q .* T) .* matlibre_densite_normale(d1) .* sigma ./ (2 * sqrt(T));
    thetaCall = commun - r .* K .* exp(-r .* T) .* N(d2) + ...
                q .* S .* exp(-q .* T) .* N(d1);
    thetaPut = commun + r .* K .* exp(-r .* T) .* N(-d2) - ...
               q .* S .* exp(-q .* T) .* N(-d1);
end
