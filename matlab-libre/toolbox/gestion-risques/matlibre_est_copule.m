function oui = matlibre_est_copule(modele)
%MATLIBRE_EST_COPULE Le modèle est-il un portefeuille de crédit simulé ?
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
    oui = isa(modele, 'creditDefaultCopula') || isa(modele, 'creditMigrationCopula');
end
