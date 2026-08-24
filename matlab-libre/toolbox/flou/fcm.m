function [centres, U, historique] = fcm(donnees, nClusters, options)
%FCM Classification par c-moyennes floues.
%   [C,U,J] = FCM(DONNEES,N) partage les lignes de DONNEES en N classes
%   floues. C porte les centres, une ligne par classe ; U(i,j) est le
%   degré d'appartenance du point j à la classe i, les colonnes sommant à
%   un ; J retrace la valeur du critère à chaque itération.
%
%   FCM(DONNEES,N,OPTIONS) où OPTIONS vaut
%     [EXPOSANT MAXITER TOLERANCE AFFICHAGE]
%   valant par défaut [2 100 1e-5 0]. L'exposant, souvent noté m, règle le
%   flou : à m proche de un la partition devient nette, et plus m grandit
%   plus les appartenances s'égalisent.
%
%   Le critère minimisé est somme_i somme_j U(i,j)^m ||x_j - c_i||^2. À
%   chaque tour, les centres sont les barycentres pondérés des points, et
%   les appartenances l'inverse des distances élevées à la puissance
%   2/(m-1), normalisé : c'est le point fixe des conditions d'optimalité.
%
%   Exemple :
%      donnees = [randn(50,2); randn(50,2) + 6];
%      [c, u] = fcm(donnees, 2);
%
%   Voir aussi SUBCLUST, GENFIS2, EVALFIS.
    if nargin < 3 || isempty(options), options = []; end
    reglages = [2, 100, 1e-5, 0];
    for k = 1:min(numel(options), 4)
        if ~isnan(options(k)), reglages(k) = options(k); end
    end
    m = reglages(1);
    maxIterations = round(reglages(2));
    tolerance = reglages(3);
    affichage = reglages(4);
    if m <= 1
        error('fuzzy:fcm:BadExponent', 'L''exposant doit dépasser un.');
    end
    X = double(donnees);
    n = size(X, 1);
    nClusters = round(nClusters);
    if nClusters < 1 || nClusters > n
        error('fuzzy:fcm:BadCount', 'Le nombre de classes doit être entre 1 et %d.', n);
    end
    % Initialisation : appartenances aléatoires, normalisées par colonne.
    U = rand(nClusters, n);
    U = U ./ repmat(sum(U, 1), nClusters, 1);
    historique = zeros(maxIterations, 1);
    centres = zeros(nClusters, size(X, 2));
    for iteration = 1:maxIterations
        Um = U .^ m;
        centres = (Um * X) ./ repmat(sum(Um, 2), 1, size(X, 2));
        distances = matriceDistances(X, centres);
        historique(iteration) = sum(sum((distances .^ 2) .* Um));
        U = appartenancesDepuisDistances(distances, m);
        if affichage
            fprintf('fcm : iteration %d, critere %.6f\n', iteration, historique(iteration));
        end
        if iteration > 1 && abs(historique(iteration - 1) - historique(iteration)) < tolerance
            historique = historique(1:iteration);
            break
        end
    end
    if numel(historique) > iteration
        historique = historique(1:iteration);
    end
end

function distances = matriceDistances(X, centres)
%MATRICEDISTANCES Distance euclidienne de chaque point à chaque centre.
    nClusters = size(centres, 1);
    n = size(X, 1);
    distances = zeros(nClusters, n);
    for i = 1:nClusters
        ecarts = X - repmat(centres(i, :), n, 1);
        distances(i, :) = sqrt(sum(ecarts .^ 2, 2))';
    end
end

function U = appartenancesDepuisDistances(distances, m)
%APPARTENANCESDEPUISDISTANCES Point fixe des conditions d'optimalité.
%   Un point qui tombe exactement sur un centre lui appartient entièrement.
    distances = max(distances, eps);
    puissance = distances .^ (-2 / (m - 1));
    U = puissance ./ repmat(sum(puissance, 1), size(distances, 1), 1);
    surCentre = any(distances < 1e-12, 1);
    for j = find(surCentre)
        colonne = zeros(size(distances, 1), 1);
        [~, plusProche] = min(distances(:, j));
        colonne(plusProche) = 1;
        U(:, j) = colonne;
    end
end
