function [echecs, nombre, compte, attendu] = matlibre_var_echecs(modele)
%MATLIBRE_VAR_ECHECS Dépassements d'un modèle de valeur en risque.
%   Un dépassement est une perte plus grande que la valeur en risque
%   annoncée : le rendement tombe sous l'opposé de celle-ci.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
    echecs = modele.PortfolioData < -modele.VaRData;
    nombre = numel(echecs);
    compte = sum(echecs);
    attendu = (1 - modele.VaRLevel) * nombre;
end
