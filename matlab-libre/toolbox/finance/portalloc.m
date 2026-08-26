function [poids, rendement, risque] = portalloc(rendements, covariance, cible)
%PORTALLOC Portefeuille de variance minimale pour un rendement cible.
%   Résolution analytique par multiplicateurs de Lagrange.
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
