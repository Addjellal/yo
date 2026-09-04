function [pValeur, valeurCritique] = matlibre_quantiles_gauche(statistique, niveaux, quantiles, alpha)
%MATLIBRE_QUANTILES_GAUCHE Valeur p et valeur critique d'un test à gauche.
%   NIVEAUX et QUANTILES décrivent la loi tabulée ; la valeur critique est
%   le quantile d'ordre ALPHA, et la valeur p la proportion de la loi
%   située sous la statistique. En dehors de la table, la valeur p est
%   ramenée au niveau extrême le plus proche : la table ne sait rien
%   au-delà.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
    valeurCritique = interp1(niveaux, quantiles, alpha, 'linear', 'extrap');
    if statistique <= quantiles(1)
        pValeur = niveaux(1);
    elseif statistique >= quantiles(end)
        pValeur = niveaux(end);
    else
        pValeur = interp1(quantiles, niveaux, statistique, 'linear');
    end
end
