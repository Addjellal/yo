function pertes = getScenarios(modele, indices)
%GETSCENARIOS Pertes simulées d'un portefeuille de crédit.
%   P = GETSCENARIOS(C) rend la perte de chaque contrepartie dans chaque
%   scénario : une ligne par scénario, une colonne par contrepartie.
%   GETSCENARIOS(C,I) ne rend que les scénarios demandés.
%
%   Exemple :
%      p = getScenarios(c);
%      sum(p, 2)                      % pertes de portefeuille
%
%   Voir aussi CREDITDEFAULTCOPULA, PORTFOLIORISK, RISKCONTRIBUTION.
    if ~matlibre_est_copule(modele)
        error('risque:getScenarios:Modele', ...
              'GETSCENARIOS attend un modèle de portefeuille de crédit.');
    end
    pertes = modele.Losses;
    if nargin >= 2 && ~isempty(indices)
        pertes = pertes(round(indices(:)), :);
    end
end
