function [phi, theta, phiNiveaux] = matlibre_arima_polynomes(obj)
%MATLIBRE_ARIMA_POLYNOMES Développe les polynômes du modèle.
%   PHI et THETA sont les coefficients, retard par retard, des parties
%   autorégressive et moyenne mobile de la série différenciée : le
%   produit des parties ordinaire et saisonnière est développé.
%   PHINIVEAUX ajoute les facteurs de différenciation, ce qui donne le
%   polynôme qui agit sur la série de niveau.
%
%   La convention est celle de MATLAB : y(t) = ... + phi(i) y(t-i) + ...,
%   les coefficients apparaissent donc avec le signe plus.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
    polyAR = conv(facteur(obj.ARLags, obj.AR, -1), ...
                  facteur(obj.SARLags, obj.SAR, -1));
    polyMA = conv(facteur(obj.MALags, obj.MA, 1), ...
                  facteur(obj.SMALags, obj.SMA, 1));
    phi = -polyAR(2:end);
    theta = polyMA(2:end);
    complet = polyAR;
    for k = 1:obj.D
        complet = conv(complet, [1, -1]);
    end
    if obj.Seasonality > 0
        saison = [1, zeros(1, obj.Seasonality - 1), -1];
        complet = conv(complet, saison);
    end
    phiNiveaux = -complet(2:end);
end

function p = facteur(retards, coefficients, signe)
%FACTEUR Polynôme 1 + signe * somme des coefficients aux retards donnés.
    if isempty(retards)
        p = 1;
        return
    end
    p = zeros(1, max(retards) + 1);
    p(1) = 1;
    for k = 1:numel(retards)
        p(retards(k) + 1) = signe * coefficients{k};
    end
end
