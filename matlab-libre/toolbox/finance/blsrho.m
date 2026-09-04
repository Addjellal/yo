function [rhoCall, rhoPut] = blsrho(S, K, r, T, sigma, q)
%BLSRHO Sensibilité du prix d'une option au taux d'intérêt.
%   [RC,RP] = BLSRHO(S,K,R,T,SIGMA) rend la dérivée du prix par rapport
%   au taux sans risque. Elle est positive pour un achat, négative pour
%   une vente : un taux plus élevé abaisse la valeur actuelle du prix
%   d'exercice.
%
%   Exemple :
%      blsrho(100, 100, 0.05, 1, 0.2)
%
%   Voir aussi BLSPRICE, BLSDELTA, BLSGAMMA, BLSVEGA, BLSTHETA.
    if nargin < 6, q = 0; end
    [~, d2] = matlibre_bls_d(S, K, r, T, sigma, q);
    N = @(x) 0.5 * erfc(-x / sqrt(2));
    rhoCall = K .* T .* exp(-r .* T) .* N(d2);
    rhoPut = -K .* T .* exp(-r .* T) .* N(-d2);
end
