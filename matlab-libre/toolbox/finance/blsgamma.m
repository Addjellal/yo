function gamma = blsgamma(S, K, r, T, sigma, q)
%BLSGAMMA Courbure du prix d'une option par rapport au cours.
%   G = BLSGAMMA(S,K,R,T,SIGMA) rend la dérivée seconde du prix par
%   rapport au cours du sous-jacent — autrement dit, la vitesse à
%   laquelle le delta change.
%
%   Le gamma est le même pour l'achat et pour la vente : la parité
%   achat-vente ne fait intervenir que des termes linéaires en S.
%
%   Exemple :
%      blsgamma(100, 100, 0.05, 1, 0.2)
%
%   Voir aussi BLSPRICE, BLSDELTA, BLSVEGA, BLSTHETA, BLSRHO.
    if nargin < 6, q = 0; end
    d1 = matlibre_bls_d(S, K, r, T, sigma, q);
    gamma = exp(-q .* T) .* matlibre_densite_normale(d1) ./ (S .* sigma .* sqrt(T));
end
