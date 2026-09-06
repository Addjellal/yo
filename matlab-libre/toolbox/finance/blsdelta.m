function [deltaCall, deltaPut] = blsdelta(S, K, r, T, sigma, q)
%BLSDELTA Sensibilité du prix au cours du sous-jacent.
%   [DC,DP] = BLSDELTA(S,K,R,T,SIGMA) rend la dérivée du prix Black-Scholes
%   par rapport au cours du sous-jacent, pour l'option d'achat et pour
%   l'option de vente. S est le cours, K le prix d'exercice, R le taux sans
%   risque continu, T l'échéance en années, SIGMA la volatilité annuelle.
%   [DC,DP] = BLSDELTA(S,K,R,T,SIGMA,Q) tient compte d'un rendement de
%   dividende continu Q.
%
%   Le delta d'un achat va de 0 à exp(-Q*T) : très en dehors de la monnaie
%   l'option ne bouge plus, très en dedans elle suit le sous-jacent
%   quasiment un pour un. Delta se lit donc comme le nombre d'actions à
%   détenir pour neutraliser le risque de première grandeur — c'est la
%   couverture en delta, et c'est en la répliquant en continu que la
%   formule de Black-Scholes se démontre.
%
%   Les deux deltas diffèrent exactement de exp(-Q*T), ce qui n'est autre
%   que la parité achat-vente dérivée une fois : détenir un achat et vendre
%   une vente équivaut à détenir le sous-jacent.
%
%   Exemple :
%      [dc, dp] = blsdelta(100, 100, 0.05, 1, 0.2);
%      dc - dp
%
%   Voir aussi BLSPRICE, BLSGAMMA, BLSVEGA, BLSIMPV.
    if nargin < 6
        q = 0;
    end
    d1 = (log(S ./ K) + (r - q + sigma .^ 2 / 2) .* T) ./ (sigma .* sqrt(T));
    N = @(x) 0.5 * erfc(-x / sqrt(2));
    deltaCall = exp(-q * T) .* N(d1);
    deltaPut = deltaCall - exp(-q * T);
end
