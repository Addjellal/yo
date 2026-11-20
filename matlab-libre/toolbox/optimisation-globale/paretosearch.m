function [x, valeurs, drapeau, sortie] = paretosearch(fonction, nVariables, A, b, Aeq, beq, bas, haut, nonlin, options)
%PARETOSEARCH Front de Pareto par recherche directe sur maillage.
%   [X,F] = PARETOSEARCH(FONCTION,N,[],[],[],[],BAS,HAUT) cherche le front
%   de Pareto de FONCTION, qui rend un vecteur d'objectifs, sans gradient
%   ni hasard de croisement. X a une ligne par point non dominé, F la
%   valeur des objectifs.
%   [X,F] = PARETOSEARCH(...,[],OPTIONS) lit 'ParetoSetSize' (60, comme
%   MATLAB), 'MaxIterations' (100 fois le nombre de variables) et
%   'MeshTolerance' (1e-6, rapportée à l'étendue de chaque variable).
%   [X,F,DRAPEAU,SORTIE] = PARETOSEARCH(...) rend aussi le nombre
%   d'itérations et d'évaluations.
%
%   Chaque point de l'archive non dominée porte sa propre maille, comme
%   dans une recherche par motifs : il sonde les 2N directions de
%   coordonnée ; un sondage qui entre dans l'archive y entre avec une
%   maille doublée, et un point dont aucun sondage n'a réussi resserre la
%   sienne de moitié. Le pas ne se resserre donc que là où il le faut, et
%   les points peuvent parcourir tout le domaine. L'archive est ramenée à
%   ParetoSetSize points par la distance d'encombrement, extrémités
%   gardées. Chaque itération sonde les dix points actifs les plus isolés.
%   Sur le problème ZDT1 de Zitzler, Deb et Thiele (2000), le front trouvé
%   suit la courbe f2 = 1 - racine(f1).
%
%   Seules les bornes sont prises en charge : les contraintes linéaires et
%   non linéaires sont refusées en le disant (GAMULTIOBJ prend les
%   contraintes linéaires).
%
%   Exemple :
%      f = @(x) [x(1)^2, (x(1)-2)^2];
%      [x, v] = paretosearch(f, 1, [], [], [], [], -2, 4);
%
%   Voir aussi GAMULTIOBJ, PATTERNSEARCH.
    if nargin < 3, A = []; end
    if nargin < 4, b = []; end %#ok<NASGU>
    if nargin < 5, Aeq = []; end
    if nargin < 6, beq = []; end %#ok<NASGU>
    if nargin < 7 || isempty(bas), bas = -10 * ones(1, nVariables); end
    if nargin < 8 || isempty(haut), haut = 10 * ones(1, nVariables); end
    if nargin < 9, nonlin = []; end
    if nargin < 10, options = struct(); end
    if ~isempty(nonlin)
        error('globaloptim:paretosearch:NonLineaire', ...
              'MatLibre ne prend pas encore les contraintes non linéaires de PARETOSEARCH.');
    end
    if ~isempty(A) || ~isempty(Aeq)
        error('globaloptim:paretosearch:Lineaire', ...
              'MatLibre ne prend que des bornes dans PARETOSEARCH : GAMULTIOBJ prend les contraintes linéaires.');
    end
    taille = champOptimisation(options, 'ParetoSetSize', 60);
    iterations = champOptimisation(options, 'MaxIterations', 100 * nVariables);
    tolerance = champOptimisation(options, 'MeshTolerance', 1e-6);
    bas = bas(:)';
    haut = haut(:)';
    etendue = haut - bas;
    points = repmat(bas, taille, 1) + rand(taille, nVariables) .* repmat(etendue, taille, 1);
    scores = evaluerListe(fonction, points);
    mailles = 0.25 * ones(taille, 1);
    [points, scores, mailles] = garderNonDomines(points, scores, mailles);
    evaluations = taille;
    iteration = 0;
    for iteration = 1:iterations
        actifs = find(mailles >= tolerance);
        if isempty(actifs)
            break
        end
        isolement = repartition(scores);
        [~, ordre] = sort(isolement(actifs), 'descend');
        sondes = actifs(ordre(1:min(10, numel(actifs))));
        candidats = zeros(0, nVariables);
        parents = zeros(0, 1);
        for k = sondes(:).'
            for d = 1:nVariables
                for signe = [1 -1]
                    c = points(k, :);
                    c(d) = min(max(c(d) + signe * mailles(k) * etendue(d), bas(d)), haut(d));
                    if c(d) ~= points(k, d)
                        candidats(end + 1, :) = c;                %#ok<AGROW>
                        parents(end + 1, 1) = k;                  %#ok<AGROW>
                    end
                end
            end
        end
        if isempty(candidats)
            mailles(sondes) = mailles(sondes) / 2;
            continue
        end
        scoresCandidats = evaluerListe(fonction, candidats);
        evaluations = evaluations + size(candidats, 1);
        n0 = size(points, 1);
        tous = [points; candidats];
        tousScores = [scores; scoresCandidats];
        tousMailles = [mailles; 2 * mailles(parents)];
        [tous, tousScores, tousMailles, gardes] = garderNonDomines(tous, tousScores, tousMailles);
        % Les points sondés dont aucun sondage n'est entré resserrent leur maille.
        reussis = unique(parents(gardes(gardes > n0) - n0));
        echecs = setdiff(sondes, reussis);
        survivantsEchoues = ismember(gardes, echecs);
        tousMailles(survivantsEchoues) = tousMailles(survivantsEchoues) / 2;
        if size(tous, 1) > taille
            d = repartition(tousScores);
            [~, ordre] = sort(d, 'descend');
            garde = ordre(1:taille);
            tous = tous(garde, :);
            tousScores = tousScores(garde, :);
            tousMailles = tousMailles(garde);
        end
        points = tous;
        scores = tousScores;
        mailles = tousMailles;
    end
    x = points;
    valeurs = scores;
    drapeau = 1;
    sortie = struct('iterations', iteration, 'funccount', evaluations, ...
                    'algorithm', 'recherche directe sur maillage');
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

function [points, scores, mailles, gardes] = garderNonDomines(points, scores, mailles)
%GARDERNONDOMINES Les points non dominés, sans doublon d'objectifs ; GARDES leurs indices.
    n = size(scores, 1);
    domine = false(n, 1);
    % Un point est dominé s'il existe une ligne au moins aussi bonne
    % partout et meilleure quelque part.
    for j = 1:n
        reference = repmat(scores(j, :), n, 1);
        domine = domine | (all(scores >= reference, 2) & any(scores > reference, 2));
    end
    gardes = find(~domine);
    [~, uniques] = unique(round(scores(gardes, :) * 1e12) / 1e12, 'rows');
    gardes = gardes(sort(uniques));
    points = points(gardes, :);
    scores = scores(gardes, :);
    mailles = mailles(gardes);
end

function d = repartition(scores)
%REPARTITION Distance d'encombrement : les extrémités valent l'infini.
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
