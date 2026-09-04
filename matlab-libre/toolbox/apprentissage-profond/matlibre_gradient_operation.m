function contributions = matlibre_gradient_operation(noeud, g)
%MATLIBRE_GRADIENT_OPERATION Dérivée d'une opération, remontée aux parents.
%   C = MATLIBRE_GRADIENT_OPERATION(NOEUD,G) rend, pour chaque parent du
%   nœud, la part de dérivée qui lui revient, sachant que la dérivée du
%   résultat est G. C'est la règle de dérivation en chaîne, écrite une
%   fois par opération.
%
%   Là où une opération a diffusé un opérande pour l'apparier à l'autre,
%   la dérivée est resommée sur les dimensions étirées : chaque copie a
%   reçu sa part, l'opérande d'origine reçoit leur somme.
%
%   Exemple :
%      n.operation = 'exp'; n.parents = 1; n.donnees = {exp(2)};
%      c = matlibre_gradient_operation(n, 1);
%      c{1}      % exp(2)
%
%   Voir aussi DLGRADIENT, MATLIBRE_BANDE.
    d = noeud.donnees;
    switch noeud.operation
        case 'feuille'
            contributions = {};
        case 'plus'
            contributions = {matlibre_reduire_gradient(g, d{1}), ...
                             matlibre_reduire_gradient(g, d{2})};
        case 'minus'
            contributions = {matlibre_reduire_gradient(g, d{1}), ...
                             matlibre_reduire_gradient(-g, d{2})};
        case 'uminus'
            contributions = {-g};
        case 'times'
            contributions = {matlibre_reduire_gradient(g .* d{2}, size(d{1})), ...
                             matlibre_reduire_gradient(g .* d{1}, size(d{2}))};
        case 'mtimes'
            contributions = {g * d{2}.', d{1}.' * g};
        case 'rdivide'
            contributions = {matlibre_reduire_gradient(g ./ d{2}, size(d{1})), ...
                             matlibre_reduire_gradient(-g .* d{1} ./ d{2} .^ 2, ...
                                                       size(d{2}))};
        case 'power'
            base = d{1};
            exposant = d{2};
            parBase = g .* exposant .* base .^ (exposant - 1);
            % La dérivée par rapport à l'exposant demande le logarithme
            % de la base : elle n'a de sens que là où la base est
            % strictement positive.
            positif = base > 0;
            parExposant = zeros(size(base .* exposant));
            if any(positif(:))
                journal = zeros(size(base));
                journal(positif) = log(base(positif));
                parExposant = g .* (base .^ exposant) .* journal;
            end
            contributions = {matlibre_reduire_gradient(parBase, size(base)), ...
                             matlibre_reduire_gradient(parExposant, size(exposant))};
        case 'exp'
            contributions = {g .* d{1}};
        case 'log'
            contributions = {g ./ d{1}};
        case 'sqrt'
            contributions = {g ./ (2 * d{1})};
        case 'tanh'
            contributions = {g .* (1 - d{1} .^ 2)};
        case 'abs'
            contributions = {g .* sign(d{1})};
        case 'sin'
            contributions = {g .* cos(d{1})};
        case 'cos'
            contributions = {-g .* sin(d{1})};
        case 'erf'
            contributions = {g .* (2 / sqrt(pi)) .* exp(-d{1} .^ 2)};
        case 'sommeTotale'
            contributions = {repmat(g, d{1})};
        case 'somme'
            repetitions = ones(1, numel(d{1}));
            repetitions(d{2}) = d{1}(d{2});
            contributions = {repmat(g, repetitions)};
        case 'moyenneTotale'
            contributions = {repmat(g, d{1}) / prod(d{1})};
        case 'moyenne'
            repetitions = ones(1, numel(d{1}));
            repetitions(d{2}) = d{1}(d{2});
            contributions = {repmat(g, repetitions) / d{1}(d{2})};
        case 'remise'
            contributions = {reshape(g, d{1})};
        case 'permutation'
            contributions = {ipermute(g, d{1})};
        case 'transposition'
            contributions = {g.'};
        case 'repetition'
            contributions = {matlibre_gradient_repetition(g, d{1}, d{2})};
        case 'extremumTermeATerme'
            if strcmp(d{3}, 'max')
                choisi = d{1} >= d{2};
            else
                choisi = d{1} <= d{2};
            end
            contributions = {matlibre_reduire_gradient(g .* choisi, size(d{1})), ...
                             matlibre_reduire_gradient(g .* ~choisi, size(d{2}))};
        case 'extremumTotal'
            gradient = zeros(d{1});
            gradient(d{2}) = g;
            contributions = {gradient};
        case 'extremumDimension'
            contributions = {matlibre_gradient_extremum(g, d{1}, d{2}, d{3})};
        case 'indexation'
            contributions = {matlibre_gradient_indexation(g, d{1}, d{2})};
        case 'affectation'
            versAncien = g;
            versAncien(d{2}{:}) = 0;
            versValeur = matlibre_reduire_gradient(g(d{2}{:}), d{3});
            contributions = {versAncien, versValeur};
        case 'concatenation'
            contributions = matlibre_gradient_concatenation(g, d{1}, d{2});
        case 'convolution'
            contributions = matlibre_gradient_convolution(g, d);
        case 'agregation'
            contributions = matlibre_gradient_agregation(g, d);
        otherwise
            error('nnet:gradient:Operation', ...
                  'Aucune règle de dérivation pour « %s ».', noeud.operation);
    end
end

function ga = matlibre_gradient_repetition(g, taille, repetitions)
% REPMAT copie l'opérande ; chaque copie reçoit sa part, l'original
% reçoit leur somme. Le découpage se lit directement dans l'ordre mémoire.
    n = max(numel(taille), numel(repetitions));
    taille = [taille, ones(1, n - numel(taille))];
    repetitions = [repetitions, ones(1, n - numel(repetitions))];
    forme = zeros(1, 2 * n);
    forme(1:2:end) = taille;
    forme(2:2:end) = repetitions;
    ga = reshape(g, forme);
    for k = n:-1:1
        ga = sum(ga, 2 * k);
    end
    ga = reshape(ga, taille);
end

function ga = matlibre_gradient_extremum(g, taille, dimension, indices)
% Seul l'élément retenu a compté : la dérivée lui revient en entier.
    tailleSortie = taille;
    tailleSortie(dimension) = 1;
    sousIndices = cell(1, numel(taille));
    [sousIndices{:}] = ind2sub(tailleSortie, (1:prod(tailleSortie)).');
    sousIndices{dimension} = indices(:);
    lineaires = sub2ind(taille, sousIndices{:});
    ga = zeros(prod(taille), 1);
    ga(lineaires) = g(:);
    ga = reshape(ga, taille);
end

function ga = matlibre_gradient_indexation(g, taille, indices)
% L'indexation choisit des positions ; la dérivée retourne s'y accumuler.
% Passer par les numéros linéaires traite d'un coup toutes les formes
% d'indexation, y compris celles qui répètent une position.
    reperes = reshape(1:prod(taille), taille);
    choisis = reperes(indices{:});
    ga = accumarray(choisis(:), g(:), [prod(taille) 1]);
    ga = reshape(ga, taille);
end

function contributions = matlibre_gradient_concatenation(g, dimension, tailles)
% Chaque opérande reprend la tranche qui vient de lui.
    contributions = cell(1, numel(tailles));
    debut = 1;
    decoupe = repmat({':'}, 1, max(dimension, ndims(g)));
    for k = 1:numel(tailles)
        largeur = tailles{k};
        if dimension <= numel(largeur)
            epaisseur = largeur(dimension);
        else
            epaisseur = 1;
        end
        decoupe{dimension} = debut:(debut + epaisseur - 1);
        contributions{k} = reshape(g(decoupe{:}), tailles{k});
        debut = debut + epaisseur;
    end
end
