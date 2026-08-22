function [meilleur, valeur] = ga(fonction, nVariables, bas, haut, options)
%GA Algorithme génétique à codage réel.
%   [X,F] = GA(FONCTION,N,BAS,HAUT) minimise FONCTION sur l'hypercube.
    if nargin < 5
        options = struct();
    end
    taille = champOuDefaut(options, 'PopulationSize', 50);
    generations = champOuDefaut(options, 'Generations', 100);
    mutation = champOuDefaut(options, 'MutationRate', 0.1);
    bas = bas(:).';
    haut = haut(:).';
    population = repmat(bas, taille, 1) + rand(taille, nVariables) .* ...
                 repmat(haut - bas, taille, 1);
    scores = zeros(taille, 1);
    for k = 1:taille
        scores(k) = fonction(population(k, :));
    end
    for g = 1:generations
        [scores, ordre] = sort(scores);
        population = population(ordre, :);
        elite = max(2, round(taille / 5));
        nouvelle = population(1:elite, :);
        while size(nouvelle, 1) < taille
            a = population(randi([1 elite]), :);
            b = population(randi([1 elite]), :);
            alpha = rand(1, nVariables);
            enfant = alpha .* a + (1 - alpha) .* b;
            masque = rand(1, nVariables) < mutation;
            enfant(masque) = bas(masque) + rand(1, sum(masque)) .* ...
                             (haut(masque) - bas(masque));
            nouvelle(end+1, :) = enfant;
        end
        population = nouvelle(1:taille, :);
        for k = 1:taille
            scores(k) = fonction(population(k, :));
        end
    end
    [valeur, k] = min(scores);
    meilleur = population(k, :);
end

function v = champOuDefaut(s, nom, defaut)
    if isstruct(s) && isfield(s, nom)
        v = s.(nom);
    else
        v = defaut;
    end
end
