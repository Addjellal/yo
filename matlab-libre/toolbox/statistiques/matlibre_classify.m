function [classe, erreur, posterieure, logp, coeff] = ...
    matlibre_classify(echantillon, apprentissage, groupe, genre, apriori)
%MATLIBRE_CLASSIFY Analyse discriminante de CLASSIFY (Statistics Toolbox).
%   Appelée par CLASSIFY quand son premier argument est une matrice
%   d'observations, non un réseau. Voir CLASSIFY.
%
%   Chaque groupe est supposé gaussien ; une observation va au groupe de
%   plus grande probabilité a posteriori. Le genre fixe la covariance :
%      'linear'         commune, estimée en regroupant les groupes
%                       (dénominateur N - G) — c'est le défaut ;
%      'diaglinear'     commune et diagonale ;
%      'quadratic'      propre à chaque groupe (dénominateur Nk - 1) ;
%      'diagquadratic'  propre à chaque groupe et diagonale ;
%      'mahalanobis'    distance de Mahalanobis à chaque groupe, avec sa
%                       propre covariance, sans probabilités.
%   Les a priori valent par défaut 1/G pour chaque groupe ; 'empirical'
%   les prend proportionnels aux effectifs ; un vecteur, ou une
%   structure aux champs prob et group, les fixe.
    if nargin < 4 || isempty(genre)
        genre = 'linear';
    end
    genre = lower(char(genre));
    genres = {'linear', 'diaglinear', 'quadratic', 'diagquadratic', 'mahalanobis'};
    if ~any(strcmp(genre, genres))
        error('stats:classify:BadType', ...
              'Discriminant type is ''%s''; it must be one of %s.', ...
              genre, strjoin(genres, ', '));
    end
    if ~isnumeric(echantillon) || ~isnumeric(apprentissage)
        error('stats:classify:BadData', ...
              'CLASSIFY requires numeric matrices of observations.');
    end
    echantillon = double(echantillon);
    apprentissage = double(apprentissage);
    if size(echantillon, 2) ~= size(apprentissage, 2)
        error('stats:classify:SampleTrainingSizeMismatch', ...
              'SAMPLE and TRAINING must have the same number of columns.');
    end

    [indices, noms, niveaux] = groupesDe(groupe);
    if numel(indices) ~= size(apprentissage, 1)
        error('stats:classify:TrainingGroupSizeMismatch', ...
              'GROUP must have one value per row of TRAINING.');
    end
    % Les lignes d'apprentissage incomplètes ne comptent pas.
    valides = ~isnan(indices) & ~any(isnan(apprentissage), 2);
    apprentissage = apprentissage(valides, :);
    indices = indices(valides);
    G = numel(noms);
    [n, d] = size(apprentissage);
    effectifs = accumarray(indices, 1, [G 1]);
    if any(effectifs == 0)
        % Un groupe sans observation valide ne peut être décrit.
        presents = effectifs > 0;
        correspondance = cumsum(presents);
        indices = correspondance(indices);
        noms = noms(presents);
        niveaux = niveaux(presents, :);
        effectifs = effectifs(presents);
        G = numel(noms);
    end
    if G < 2
        error('stats:classify:TooFewGroups', 'At least two groups are required.');
    end

    if nargin < 5
        apriori = [];
    end
    apriori = lireApriori(apriori, effectifs, noms);

    moyennes = zeros(G, d);
    for k = 1:G
        moyennes(k, :) = mean(apprentissage(indices == k, :), 1);
    end
    centres = apprentissage - moyennes(indices, :);

    % Les facteurs de covariance : SIGMA = R' * R pour chaque groupe.
    facteurs = cell(G, 1);
    logDet = zeros(G, 1);
    switch genre
        case 'linear'
            if n <= G
                error('stats:classify:NoDOF', ...
                      'Too few observations to estimate the pooled covariance.');
            end
            [~, R] = qr(centres, 0);
            R = R / sqrt(n - G);
            verifierRang(R, n, d, 'stats:classify:BadLinearVar', ...
                         'The pooled covariance matrix of TRAINING must be positive definite.');
            [facteurs{:}] = deal(R);
            logDet(:) = 2 * sum(log(abs(diag(R))));
        case 'diaglinear'
            ecarts = sqrt(sum(centres .^ 2, 1) / (n - G));
            if any(ecarts == 0)
                error('stats:classify:BadDiagLinearVar', ...
                      'A variable has zero pooled variance.');
            end
            [facteurs{:}] = deal(diag(ecarts));
            logDet(:) = 2 * sum(log(ecarts));
        case {'quadratic', 'mahalanobis'}
            for k = 1:G
                if effectifs(k) < 2
                    error('stats:classify:GroupTooSmall', ...
                          'Group %s has fewer than two observations.', noms{k});
                end
                [~, R] = qr(centres(indices == k, :), 0);
                R = R / sqrt(effectifs(k) - 1);
                verifierRang(R, effectifs(k), d, 'stats:classify:BadQuadVar', ...
                             sprintf(['The covariance matrix of each group in TRAINING must be ' ...
                                      'positive ' ...
                                      'definite (group %s).'], noms{k}));
                facteurs{k} = R;
                logDet(k) = 2 * sum(log(abs(diag(R))));
            end
        case 'diagquadratic'
            for k = 1:G
                if effectifs(k) < 2
                    error('stats:classify:GroupTooSmall', ...
                          'Group %s has fewer than two observations.', noms{k});
                end
                ecarts = sqrt(sum(centres(indices == k, :) .^ 2, 1) / (effectifs(k) - 1));
                if any(ecarts == 0)
                    error('stats:classify:BadDiagQuadVar', ...
                          'A variable has zero variance in group %s.', noms{k});
                end
                facteurs{k} = diag(ecarts);
                logDet(k) = 2 * sum(log(ecarts));
            end
    end

    D = scoresDe(echantillon, moyennes, facteurs, logDet, apriori, genre);
    [maxD, choisis] = max(D, [], 2);
    incompletes = any(isnan(echantillon), 2);
    classe = etiquettesDe(niveaux, choisis, incompletes);

    if nargout > 1
        % L'erreur apparente : la part des observations d'apprentissage
        % mal classées, groupe par groupe, pondérée par les a priori.
        Da = scoresDe(apprentissage, moyennes, facteurs, logDet, apriori, genre);
        [~, choisisA] = max(Da, [], 2);
        manques = choisisA ~= indices;
        taux = accumarray(indices, manques, [G 1]) ./ effectifs;
        erreur = apriori(:).' * taux;
    end
    if nargout > 2
        if strcmp(genre, 'mahalanobis')
            posterieure = [];
            logp = [];
        else
            P = exp(D - maxD);
            sommeP = sum(P, 2);
            posterieure = P ./ sommeP;
            logp = log(sommeP) + maxD - 0.5 * d * log(2 * pi);
            posterieure(incompletes, :) = NaN;
            logp(incompletes) = NaN;
        end
    end
    if nargout > 4
        coeff = coefficientsDeFrontiere(moyennes, facteurs, logDet, apriori, genre, noms);
    end
end

% Les scores de chaque observation pour chaque groupe : le logarithme de
% la densité a posteriori, à une constante près.
function D = scoresDe(X, moyennes, facteurs, logDet, apriori, genre)
    G = size(moyennes, 1);
    D = zeros(size(X, 1), G);
    for k = 1:G
        A = (X - moyennes(k, :)) / facteurs{k};
        distance = sum(A .* A, 2);
        if strcmp(genre, 'mahalanobis')
            D(:, k) = -distance;
        else
            D(:, k) = log(apriori(k)) - 0.5 * (distance + logDet(k));
        end
    end
end

function verifierRang(R, n, d, identifiant, message)
    s = svd(R);
    if size(R, 1) < d || isempty(s) || any(s <= max(n, d) * eps(max(s)))
        error(identifiant, '%s', message);
    end
end

% Les frontières entre groupes : K + x*L (+ x*Q*x') = 0, positif du côté
% du groupe I.
function coeff = coefficientsDeFrontiere(moyennes, facteurs, logDet, apriori, genre, noms)
    G = size(moyennes, 1);
    gabarit = struct('type', genre, 'name1', '', 'name2', '', 'const', [], ...
                     'linear', [], 'quadratic', []);
    coeff = repmat(gabarit, G, G);
    if strcmp(genre, 'mahalanobis')
        for i = 1:G
            for j = 1:G
                coeff(i, j).name1 = noms{i};
                coeff(i, j).name2 = noms{j};
            end
        end
        return
    end
    lineaire = any(strcmp(genre, {'linear', 'diaglinear'}));
    for i = 1:G
        for j = 1:G
            coeff(i, j).name1 = noms{i};
            coeff(i, j).name2 = noms{j};
            if i == j
                continue
            end
            Si = facteurs{i}' * facteurs{i};
            Sj = facteurs{j}' * facteurs{j};
            mi = moyennes(i, :);
            mj = moyennes(j, :);
            if lineaire
                L = Si \ (mi - mj)';
                K = log(apriori(i) / apriori(j)) - 0.5 * (mi / Si * mi' - mj / Sj * mj');
                coeff(i, j).const = K;
                coeff(i, j).linear = L;
            else
                Ii = inv(Si);
                Ij = inv(Sj);
                K = log(apriori(i) / apriori(j)) - 0.5 * (logDet(i) - logDet(j)) ...
                    - 0.5 * (mi * Ii * mi' - mj * Ij * mj');
                coeff(i, j).const = K;
                coeff(i, j).linear = Ii * mi' - Ij * mj';
                coeff(i, j).quadratic = -0.5 * (Ii - Ij);
            end
        end
    end
end

% Les groupes : les indices, les noms (texte) et les niveaux dans le type
% du groupe d'origine, pour rendre les classes sous ce même type.
function [indices, noms, niveaux] = groupesDe(groupe)
    if iscategorical(groupe)
        groupe = groupe(:);
        noms = categories(groupe);
        [~, indices] = ismember(cellstr(groupe), noms);
        indices = double(indices);
        indices(isundefined(groupe)) = NaN;
        niveaux = categorical(noms, noms);
        return
    end
    if ischar(groupe)
        texte = cellstr(groupe);
        [indices, noms] = grp2idx(texte);
        niveaux = char(noms);
        return
    end
    if isstring(groupe)
        [indices, noms] = grp2idx(cellstr(groupe(:)));
        niveaux = string(noms);
        return
    end
    if iscell(groupe)
        [indices, noms] = grp2idx(groupe(:));
        niveaux = noms;
        return
    end
    groupe = groupe(:);
    [indices, noms] = grp2idx(double(groupe));
    distincts = unique(groupe(~isnan(double(groupe))));
    niveaux = distincts(:);
end

function classe = etiquettesDe(niveaux, choisis, incompletes)
    if ischar(niveaux)
        classe = niveaux(choisis, :);
        classe(incompletes, :) = ' ';
    elseif iscell(niveaux)
        classe = niveaux(choisis);
        classe(incompletes) = {''};
    elseif isstring(niveaux)
        classe = niveaux(choisis);
        classe(incompletes) = missing;
    elseif iscategorical(niveaux)
        classe = niveaux(choisis);
        classe(incompletes) = '<undefined>';
    else
        classe = niveaux(choisis);
        if isfloat(classe)
            classe(incompletes) = NaN;
        end
    end
end

function apriori = lireApriori(valeur, effectifs, noms)
    G = numel(effectifs);
    if isempty(valeur)
        apriori = ones(1, G) / G;
        return
    end
    if ischar(valeur) || isstring(valeur)
        if ~strcmpi(char(valeur), 'empirical')
            error('stats:classify:BadPrior', ...
                  'PRIOR must be ''empirical'', a vector, or a structure.');
        end
        apriori = effectifs(:).' / sum(effectifs);
        return
    end
    if isstruct(valeur)
        if ~isfield(valeur, 'prob') || ~isfield(valeur, 'group')
            error('stats:classify:BadPrior', ...
                  'A PRIOR structure must have fields prob and group.');
        end
        [~, nomsPrior] = groupesDeNoms(valeur.group);
        apriori = zeros(1, G);
        for k = 1:G
            i = find(strcmp(nomsPrior, noms{k}), 1);
            if isempty(i)
                error('stats:classify:BadPrior', ...
                      'PRIOR does not give the probability of group %s.', noms{k});
            end
            apriori(k) = valeur.prob(i);
        end
    else
        apriori = double(valeur(:)).';
        if numel(apriori) ~= G
            error('stats:classify:BadPrior', ...
                  'PRIOR must have one probability per group (%d here).', G);
        end
    end
    if any(apriori < 0) || ~any(apriori > 0)
        error('stats:classify:BadPrior', 'Prior probabilities must be positive.');
    end
    apriori = apriori / sum(apriori);
end

function [indices, noms] = groupesDeNoms(groupe)
    if iscategorical(groupe) || isstring(groupe) || ischar(groupe)
        noms = cellstr(groupe);
        noms = noms(:);
    elseif iscell(groupe)
        noms = groupe(:);
    else
        valeurs = groupe(:);
        noms = cell(numel(valeurs), 1);
        for k = 1:numel(valeurs)
            noms{k} = num2str(valeurs(k));
        end
    end
    indices = (1:numel(noms))';
end
