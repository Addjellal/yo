function [lambdaCall, lambdaPut] = blslambda(S, K, r, T, sigma, q)
%BLSLAMBDA Élasticité du prix d'une option au cours du sous-jacent.
%   [LC,LP] = BLSLAMBDA(S,K,R,T,SIGMA) rend la variation relative du prix
%   pour une variation relative du cours : le delta multiplié par le
%   cours et divisé par le prix.
%
%   C'est la mesure de l'effet de levier. Une option très en dehors de la
%   monnaie a un delta faible mais une élasticité énorme : elle coûte peu
%   et double de valeur pour quelques pour cent de hausse.
%
%   Exemple :
%      blslambda(100, 100, 0.05, 1, 0.2)
%
%   Voir aussi BLSDELTA, BLSPRICE, BLSGAMMA.
    if nargin < 6, q = 0; end
    [call, put] = blsprice(S, K, r, T, sigma, q);
    [deltaCall, deltaPut] = blsdelta(S, K, r, T, sigma, q);
    lambdaCall = deltaCall .* S ./ call;
    lambdaPut = deltaPut .* S ./ put;
end
