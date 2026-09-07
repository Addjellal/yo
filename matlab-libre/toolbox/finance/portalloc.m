function [poids, rendement, risque] = portalloc(rendements, covariance, cible)
%PORTALLOC Portefeuille de variance minimale pour un rendement cible.
%   Résolution analytique par multiplicateurs de Lagrange.
%
%   Exemple :
%      C = [0.04 0.01; 0.01 0.09];
%      [poids, r, risque] = portalloc([0.08 0.12], C, 0.10);
%      abs(sum(poids) - 1) < 1e-9      % le portefeuille est pleinement investi
%
%   Voir aussi PORTSTATS, SHARPE, MAXDRAWDOWN.
    n = numel(rendements);
    mu = rendements(:);
    un = ones(n, 1);
    Ci = inv(covariance);
    a = un.' * Ci * un;
    b = un.' * Ci * mu;
    c = mu.' * Ci * mu;
    d = a * c - b ^ 2;
    if nargin < 3 || isempty(cible)
        poids = (Ci * un) / a;   % variance minimale globale
    else
        lambda = (c - b * cible) / d;
        gamma = (a * cible - b) / d;
        poids = Ci * (lambda * un + gamma * mu);
    end
    rendement = mu.' * poids;
    risque = sqrt(poids.' * covariance * poids);
end
