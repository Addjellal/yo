function [information, valeurInformation] = bininfo(grille, variable)
%BININFO Contenu des tranches d'une caractéristique.
%   [T,IV] = BININFO(SC,VARIABLE) rend, tranche par tranche, le nombre de
%   bons et de mauvais dossiers, leur rapport, le poids de la preuve, et
%   la valeur d'information de la caractéristique entière.
%
%   Le poids de la preuve d'une tranche est le logarithme du rapport
%   entre la part des bons qu'elle contient et la part des mauvais : il
%   est positif là où les bons dossiers se concentrent. La valeur
%   d'information somme ces écarts, pondérés : elle dit à quel point la
%   caractéristique sépare.
%
%   Exemple :
%      [t, iv] = bininfo(sc, 'revenu')
%
%   Voir aussi AUTOBINNING, BINDATA, FITMODEL, DISPLAYPOINTS.
    if nargin < 2
        variable = grille.PredictorVars{1};
    end
    variable = char(variable);
    colonne = grille.Data.(variable);
    [indices, etiquettes] = matlibre_score_indices(grille, variable, colonne);
    [bons, mauvais, poids] = matlibre_score_reponse(grille);
    nombre = numel(etiquettes);
    compteBons = zeros(nombre, 1);
    compteMauvais = zeros(nombre, 1);
    for k = 1:nombre
        garde = indices == k;
        compteBons(k) = sum(poids(garde) .* bons(garde));
        compteMauvais(k) = sum(poids(garde) .* mauvais(garde));
    end
    garde = (compteBons + compteMauvais) > 0;
    etiquettes = etiquettes(garde);
    compteBons = compteBons(garde);
    compteMauvais = compteMauvais(garde);
    totalBons = sum(compteBons);
    totalMauvais = sum(compteMauvais);
    partBons = compteBons / max(totalBons, eps);
    partMauvais = compteMauvais / max(totalMauvais, eps);
    % Une tranche sans mauvais dossier donnerait un poids infini ; on
    % remplace le zéro par un demi-dossier, comme le veut l'usage.
    partBons(partBons == 0) = 0.5 / max(totalBons, eps);
    partMauvais(partMauvais == 0) = 0.5 / max(totalMauvais, eps);
    poidsPreuve = log(partBons ./ partMauvais);
    valeurInformation = sum((partBons - partMauvais) .* poidsPreuve);
    information = struct('Bin', {etiquettes(:).'}, 'Good', compteBons, ...
                         'Bad', compteMauvais, ...
                         'Odds', compteBons ./ max(compteMauvais, eps), ...
                         'WOE', poidsPreuve, 'InfoValue', valeurInformation);
end
