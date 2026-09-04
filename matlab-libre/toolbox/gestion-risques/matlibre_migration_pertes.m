function obj = matlibre_migration_pertes(obj, latentes)
%MATLIBRE_MIGRATION_PERTES Pertes d'un portefeuille par migration de notation.
%   La notation d'arrivée est la dernière dont le seuil est encore
%   dépassé par la variable latente ; la perte est l'écart de valeur entre
%   la notation de départ et celle d'arrivée. En défaut, seule la part
%   recouvrée subsiste.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
    nombre = size(latentes, 1);
    n = numel(obj.Ratings);
    nombreNotations = size(obj.TransitionMatrix, 2);
    if strcmpi(obj.Copula, 't')
        seuilsBase = tinv(normcdf(obj.Thresholds), obj.DegreesOfFreedom);
    else
        seuilsBase = obj.Thresholds;
    end
    pertes = zeros(nombre, n);
    for i = 1:n
        depart = obj.Ratings(i);
        seuils = seuilsBase(depart, :);
        colonne = latentes(:, i);
        % La notation d'arrivée est le rang du dernier seuil dépassé.
        arrivee = ones(nombre, 1);
        for j = 2:nombreNotations
            arrivee(colonne < seuils(j)) = j;
        end
        valeurDepart = obj.MigrationValues(i, depart);
        valeurs = obj.MigrationValues(i, :);
        valeurs(nombreNotations) = valeurs(nombreNotations) * (1 - obj.LGD(i));
        pertes(:, i) = valeurDepart - valeurs(arrivee).';
    end
    obj.Losses = pertes;
    obj.PortfolioLosses = sum(pertes, 2);
end
