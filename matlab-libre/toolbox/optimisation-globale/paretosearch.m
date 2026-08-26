function [x, valeurs, drapeau, sortie] = paretosearch(fonction, nVariables, A, b, Aeq, beq, bas, haut, nonlin, options)
%PARETOSEARCH Front de Pareto par recherche directe.
%   Même but que GAMULTIOBJ, mais sans hasard de croisement : chaque
%   point non dominé est sondé dans les directions de coordonnée, et le
%   front s'épaissit tant qu'on trouve mieux.
%
%   Exemple :
%      f = @(x) [x(1)^2, (x(1)-2)^2];
%      [x, v] = paretosearch(f, 1, [], [], [], [], -2, 4);
    if nargin < 3, A = []; end
    if nargin < 4, b = []; end
    if nargin < 5, Aeq = []; end
    if nargin < 6, beq = []; end
    if nargin < 7 || isempty(bas), bas = -10 * ones(1, nVariables); end
    if nargin < 8 || isempty(haut), haut = 10 * ones(1, nVariables); end
    if nargin < 9, nonlin = []; end
    if nargin < 10, options = struct(); end
    taille = champOptimisation(options, 'ParetoSetSize', 40);
    tours = champOptimisation(options, 'MaxIterations', 60);
    bas = bas(:)';
    haut = haut(:)';
    points = repmat(bas, taille, 1) + ...
             rand(taille, nVariables) .* repmat(haut - bas, taille, 1);
    scores = evaluerListe(fonction, points);
    pas = (haut - bas) / 8;
    for tour = 1:tours
        nouveaux = [];
        for k = 1:size(points, 1)
            for d = 1:nVariables
                for signe = [1 -1]
                    candidat = points(k, :);
                    candidat(d) = candidat(d) + signe * pas(d);
                    candidat = min(max(candidat, bas), haut);
                    nouveaux(end + 1, :) = candidat;      %#ok<AGROW>
                end
            end
        end
        tous = [points; nouveaux];
        tousScores = [scores; evaluerListe(fonction, nouveaux)];
        [tous, tousScores] = garderNonDomines(tous, tousScores);
        if size(tous, 1) > taille
            d = repartition(tousScores);
            [~, ordre] = sort(d, 'descend');
            tous = tous(ordre(1:taille), :);
            tousScores = tousScores(ordre(1:taille), :);
        end
        points = tous;
        scores = tousScores;
        pas = pas / 1.3;
    end
    x = points;
    valeurs = scores;
    drapeau = 1;
    sortie = struct('iterations', tours, 'algorithm', 'recherche de Pareto directe');
    nonlin = nonlin;                                       %#ok<ASGSL>
end

function scores = evaluerListe(fonction, points)
    if isempty(points)
        scores = [];
        return
    end
    premier = fonction(points(1, :));
    scores = zeros(size(points, 1), numel(premier));
    scores(1, :) = premier(:)';
    for k = 2:size(points, 1)
        v = fonction(points(k, :));
        scores(k, :) = v(:)';
    end
end

function [points, scores] = garderNonDomines(points, scores)
    n = size(scores, 1);
    domine = false(n, 1);
    % Un point est dominé s'il existe une ligne au moins aussi bonne
    % partout et meilleure quelque part. Le test se fait ligne par ligne
    % contre tout le lot d'un coup.
    for j = 1:n
        reference = repmat(scores(j, :), n, 1);
        domine = domine | (all(scores >= reference, 2) & any(scores > reference, 2));
    end
    garde = ~domine;
    points = points(garde, :);
    scores = scores(garde, :);
    [~, unique1] = unique(round(scores * 1e9) / 1e9, 'rows');
    points = points(sort(unique1), :);
    scores = scores(sort(unique1), :);
end

function d = repartition(scores)
%REPARTITION Écartement de chaque point sur le front, extrêmes favorisés.
    [n, m] = size(scores);
    d = zeros(n, 1);
    for objectif = 1:m
        [tries, ordre] = sort(scores(:, objectif));
        d(ordre(1)) = Inf;
        d(ordre(end)) = Inf;
        etendue = tries(end) - tries(1);
        if etendue == 0, continue, end
        for k = 2:n-1
            d(ordre(k)) = d(ordre(k)) + (tries(k + 1) - tries(k - 1)) / etendue;
        end
    end
end
