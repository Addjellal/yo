function [x, valeurs, drapeau, sortie] = gamultiobj(fonction, nVariables, A, b, Aeq, beq, bas, haut, options)
%GAMULTIOBJ Algorithme génétique multiobjectif.
%   [X,F] = GAMULTIOBJ(FONCTION,N,[],[],[],[],BAS,HAUT) cherche le front
%   de Pareto de FONCTION, qui doit rendre un vecteur d'objectifs. X a
%   une ligne par solution non dominée, F la valeur des objectifs.
%
%   La sélection est celle de NSGA-II : on classe la population par
%   rangs de domination, puis, à rang égal, par distance d'encombrement
%   — ce qui étale le front au lieu de le concentrer.
%
%   Exemple :
%      f = @(x) [x(1)^2, (x(1)-2)^2];
%      [x, v] = gamultiobj(f, 1, [], [], [], [], -2, 4);
    if nargin < 3, A = []; end
    if nargin < 4, b = []; end
    if nargin < 5, Aeq = []; end
    if nargin < 6, beq = []; end
    if nargin < 7 || isempty(bas), bas = -10 * ones(1, nVariables); end
    if nargin < 8 || isempty(haut), haut = 10 * ones(1, nVariables); end
    if nargin < 9, options = struct(); end
    taille = champOptimisation(options, 'PopulationSize', 60);
    generations = champOptimisation(options, 'MaxGenerations', 80);
    mutation = champOptimisation(options, 'MutationRate', 0.15);
    bas = bas(:)';
    haut = haut(:)';
    population = repmat(bas, taille, 1) + ...
                 rand(taille, nVariables) .* repmat(haut - bas, taille, 1);
    scores = evaluerTous(fonction, population);
    for g = 1:generations
        enfants = engendrer(population, bas, haut, mutation);
        enfants = respecterContraintes(enfants, A, b, Aeq, beq, bas, haut);
        tous = [population; enfants];
        tousScores = [scores; evaluerTous(fonction, enfants)];
        [population, scores] = selectionnerNSGA(tous, tousScores, taille);
    end
    rangs = rangsDomination(scores);
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

function enfants = engendrer(population, bas, haut, mutation)
    [n, d] = size(population);
    enfants = zeros(n, d);
    for k = 1:n
        a = population(randi(n), :);
        b = population(randi(n), :);
        alpha = rand(1, d);
        enfant = alpha .* a + (1 - alpha) .* b;
        masque = rand(1, d) < mutation;
        enfant(masque) = bas(masque) + rand(1, sum(masque)) .* (haut(masque) - bas(masque));
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
