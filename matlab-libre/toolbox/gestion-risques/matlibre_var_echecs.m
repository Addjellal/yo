function [echecs, nombre, compte, attendu, manquants] = matlibre_var_echecs(modele)
%MATLIBRE_VAR_ECHECS Dépassements d'un modèle de valeur en risque.
%   [ECHECS,N,X,ATTENDU,MANQUANTS] = MATLIBRE_VAR_ECHECS(MODELE) : un
%   dépassement est une perte plus grande que la valeur en risque annoncée
%   — le rendement tombe sous l'opposé de celle-ci. Les périodes où le
%   rendement ou la VaR manque (NaN) sont retirées, comme dans MATLAB, et
%   comptées dans MANQUANTS.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
%
%   Exemple :
%      v = varbacktest([-2; 1; NaN], [1; 1; 1], 'VaRLevel', 0.99);
%      [e, N, x] = matlibre_var_echecs(v)      % N = 2, x = 1
%
%   Voir aussi VARBACKTEST, SUMMARY.
    presents = ~isnan(modele.PortfolioData) & ~isnan(modele.VaRData);
    manquants = sum(~presents);
    echecs = modele.PortfolioData(presents) < -modele.VaRData(presents);
    nombre = numel(echecs);
    compte = sum(echecs);
    attendu = (1 - modele.VaRLevel) * nombre;
end
