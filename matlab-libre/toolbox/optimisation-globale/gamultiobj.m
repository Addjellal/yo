function [x, valeurs, drapeau, sortie] = gamultiobj(fonction, nVariables, A, b, Aeq, beq, bas, haut, ...
                                                     varargin)
%GAMULTIOBJ Algorithme génétique multiobjectif (NSGA-II).
%   [X,F] = GAMULTIOBJ(FONCTION,N,[],[],[],[],BAS,HAUT) cherche le front
%   de Pareto de FONCTION, qui doit rendre un vecteur d'objectifs. X a
%   une ligne par solution non dominée, F la valeur des objectifs.
%   [X,F] = GAMULTIOBJ(...,OPTIONS) lit 'PopulationSize' (50 jusqu'à cinq
%   variables, 200 au-delà, comme MATLAB), 'MaxGenerations' (200 fois le
%   nombre de variables) et 'CrossoverFraction' (0.8). La forme de
%   MATLAB GAMULTIOBJ(...,BAS,HAUT,NONLCON,OPTIONS) est reconnue ; les
%   contraintes linéaires sont prises, les contraintes non linéaires
%   refusées en le disant.
%
%   C'est l'algorithme NSGA-II de Deb, Pratap, Agarwal et Meyarivan
%   (2002) : les parents se choisissent par tournoi binaire sur le rang de
%   domination puis la distance d'encombrement ; les enfants naissent d'un
%   croisement intermédiaire ou d'une mutation gaussienne dont l'écart
%   type se resserre linéairement jusqu'à la dernière génération, ce qui
%   permet d'explorer d'abord et de converger ensuite ; parents et enfants
%   concourent ensemble pour la génération suivante (élitisme), classés
%   par rangs puis, à rang égal, par encombrement — ce qui étale le front.
%   Sur le problème ZDT1 de Zitzler, Deb et Thiele (2000), le front trouvé
%   suit la courbe f2 = 1 - racine(f1) au centième près.
%
%   Exemple :
%      f = @(x) [x(1)^2, (x(1)-2)^2];
%      [x, v] = gamultiobj(f, 1, [], [], [], [], -2, 4);
%
%   Voir aussi GA, PARETOSEARCH, GAOPTIMSET.
    if nargin < 3, A = []; end
    if nargin < 4, b = []; end
    if nargin < 5, Aeq = []; end
    if nargin < 6, beq = []; end
    if nargin < 7 || isempty(bas), bas = -10 * ones(1, nVariables); end
    if nargin < 8 || isempty(haut), haut = 10 * ones(1, nVariables); end
    options = struct();
    nonlin = [];
    if numel(varargin) == 1 && isa(varargin{1}, 'function_handle')
        nonlin = varargin{1};
    elseif numel(varargin) == 1
        options = varargin{1};
    elseif numel(varargin) == 2
        [nonlin, options] = varargin{:};
    elseif numel(varargin) > 2
        error('globaloptim:gamultiobj:Arguments', 'Too many input arguments for GAMULTIOBJ.');
    end
    if ~isempty(nonlin)
        error('globaloptim:gamultiobj:NonLineaire', ...
              'MatLibre does not yet support nonlinear constraints in GAMULTIOBJ.');
    end
    if isempty(options)
        options = struct();
    end
    if nVariables <= 5
        tailleDefaut = 50;
    else
        tailleDefaut = 200;
    end
    taille = champOptimisation(options, 'PopulationSize', tailleDefaut);
    generations = champOptimisation(options, 'MaxGenerations', 200 * nVariables);
    fractionCroisement = champOptimisation(options, 'CrossoverFraction', 0.8);
    bas = bas(:)';
    haut = haut(:)';
    population = repmat(bas, taille, 1) + ...
                 rand(taille, nVariables) .* repmat(haut - bas, taille, 1);
    population = respecterContraintes(population, A, b, Aeq, beq, bas, haut);
    scores = evaluerTous(fonction, population);
    [rangs, distances] = classer(scores);
    for g = 1:generations
        echelle = 0.1 * (1 - (g - 1) / generations);
        enfants = engendrer(population, rangs, distances, bas, haut, fractionCroisement, echelle);
        enfants = respecterContraintes(enfants, A, b, Aeq, beq, bas, haut);
        tous = [population; enfants];
        tousScores = [scores; evaluerTous(fonction, enfants)];
        [population, scores] = selectionnerNSGA(tous, tousScores, taille);
        [rangs, distances] = classer(scores);
    end
    premier = rangs == 1;
    x = population(premier, :);
    valeurs = scores(premier, :);
    drapeau = 1;
    sortie = struct('generations', generations, 'populationsize', taille, ...
                    'algorithm', 'NSGA-II');
end

function scores = evaluerTous(fonction, population)
    n = size(population, 1);
    premier = fonction(population(1, :));
    scores = zeros(n, numel(premier));
    scores(1, :) = premier(:)';
    for k = 2:n
        v = fonction(population(k, :));
        scores(k, :) = v(:)';
    end
end

function [rangs, distances] = classer(scores)
%CLASSER Rangs de domination, et distance d'encombrement au sein de chaque rang.
    rangs = rangsDomination(scores);
    distances = zeros(size(rangs));
    for r = 1:max(rangs)
        membres = find(rangs == r);
        distances(membres) = encombrement(scores(membres, :));
    end
end

function gagnant = tournoi(rangs, distances)
%TOURNOI Tournoi binaire : le meilleur rang, puis le moins encombré.
    n = numel(rangs);
    a = randi(n);
    b = randi(n);
    if rangs(a) < rangs(b) || (rangs(a) == rangs(b) && distances(a) > distances(b))
        gagnant = a;
    else
        gagnant = b;
    end
end

function enfants = engendrer(population, rangs, distances, bas, haut, fraction, echelle)
    [n, d] = size(population);
    enfants = zeros(n, d);
    etendue = haut - bas;
    for k = 1:n
        a = population(tournoi(rangs, distances), :);
        if rand() < fraction
            % Croisement intermédiaire : un point du pavé des deux parents.
            b = population(tournoi(rangs, distances), :);
            enfant = a + rand(1, d) .* (b - a);
        else
            % Mutation gaussienne, sur un gène au moins.
            masque = rand(1, d) < 1 / d;
            masque(randi(d)) = true;
            enfant = a;
            enfant(masque) = enfant(masque) + echelle * etendue(masque) .* randn(1, nnz(masque));
        end
        enfants(k, :) = min(max(enfant, bas), haut);
    end
end

function population = respecterContraintes(population, A, b, Aeq, beq, bas, haut)
    for k = 1:size(population, 1)
        x = population(k, :);
        if ~isempty(A)
            % Projection grossière : on retire la part qui dépasse.
            depassement = A * x' - b(:);
            if any(depassement > 0)
                x = x - (depassement' * A) / max(norm(A(:)) ^ 2, eps);
            end
        end
        if ~isempty(Aeq)
            ecart = Aeq * x' - beq(:);
            x = x - (ecart' * Aeq) / max(norm(Aeq(:)) ^ 2, eps);
        end
        population(k, :) = min(max(x, bas), haut);
    end
end

function rangs = rangsDomination(scores)
%RANGSDOMINATION Rang de Pareto de chaque individu, 1 pour le front.
    n = size(scores, 1);
    rangs = zeros(n, 1);
    restants = true(n, 1);
    rang = 0;
    while any(restants)
        rang = rang + 1;
        indices = find(restants);
        sousScores = scores(indices, :);
        m = numel(indices);
        domine = false(m, 1);
        % Comparaison vectorisée : pour chaque candidat dominant, on teste
        % d'un coup toutes les lignes. C'est m passes au lieu de m au carré.
        for j = 1:m
            reference = repmat(sousScores(j, :), m, 1);
            domine = domine | (all(sousScores >= reference, 2) & ...
                               any(sousScores > reference, 2));
        end
        front = indices(~domine);
        rangs(front) = rang;
        restants(front) = false;
    end
end

function d = encombrement(scores)
%ENCOMBREMENT Distance d'encombrement de NSGA-II.
    [n, m] = size(scores);
    d = zeros(n, 1);
    for objectif = 1:m
        [tries, ordre] = sort(scores(:, objectif));
        d(ordre(1)) = Inf;
        d(ordre(end)) = Inf;
        etendue = tries(end) - tries(1);
        if etendue == 0
            continue
        end
        for k = 2:n-1
            d(ordre(k)) = d(ordre(k)) + (tries(k + 1) - tries(k - 1)) / etendue;
        end
    end
end

function [population, scores] = selectionnerNSGA(population, scores, taille)
    rangs = rangsDomination(scores);
    gardes = [];
    rang = 1;
    while numel(gardes) < taille && rang <= max(rangs)
        candidats = find(rangs == rang);
        if numel(gardes) + numel(candidats) <= taille
            gardes = [gardes; candidats(:)];               %#ok<AGROW>
        else
            d = encombrement(scores(candidats, :));
            [~, ordre] = sort(d, 'descend');
            reste = taille - numel(gardes);
            gardes = [gardes; candidats(ordre(1:reste))];  %#ok<AGROW>
        end
        rang = rang + 1;
    end
    population = population(gardes, :);
    scores = scores(gardes, :);
end
