function vega = blsvega(S, K, r, T, sigma, q)
%BLSVEGA Sensibilité du prix d'une option à la volatilité.
%   V = BLSVEGA(S,K,R,T,SIGMA) rend la dérivée du prix par rapport à la
%   volatilité. Elle est la même pour l'achat et pour la vente, et elle
%   est maximale quand l'option est à la monnaie.
%
%   Exemple :
%      blsvega(100, 100, 0.05, 1, 0.2)
%
%   Voir aussi BLSPRICE, BLSGAMMA, BLSIMPV, BLSTHETA.
    if nargin < 6, q = 0; end
    d1 = matlibre_bls_d(S, K, r, T, sigma, q);
    vega = S .* exp(-q .* T) .* matlibre_densite_normale(d1) .* sqrt(T);
end
