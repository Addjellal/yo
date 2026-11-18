function [coeff, score, latent, tsquared, explained, mu] = pca(X, varargin)
%PCA Analyse en composantes principales.
%   COEFF = PCA(X) rend les axes principaux de X, une observation par
%   ligne et une variable par colonne : chaque colonne de COEFF est un
%   axe, rangés par variance décroissante.
%
%   [COEFF,SCORE,LATENT,TSQUARED,EXPLAINED,MU] = PCA(X) rend aussi
%      SCORE      les coordonnées des observations sur les axes ;
%      LATENT     la variance portée par chaque axe — les valeurs propres
%                 de la covariance de X ;
%      TSQUARED   le T² de Hotelling de chaque observation, la somme des
%                 carrés de ses coordonnées réduites, sur tous les axes
%                 même quand NumComponents en garde moins ;
%      EXPLAINED  la part de la variance totale portée par chaque axe, en
%                 pour cent ;
%      MU         la moyenne retranchée, une valeur par variable.
%   C'est l'ordre de MATLAB : le pourcentage expliqué est la cinquième
%   sortie, non la quatrième.
%
%   Comme MATLAB, PCA fixe le signe de chaque axe, que la décomposition
%   laisse libre : le coefficient de plus grande valeur absolue y est
%   positif.
%
%   Options, par paires nom-valeur :
%      'Algorithm'       'svd' (défaut) décompose les données centrées ;
%                        'eig' diagonalise leur covariance.
%      'Centered'        vrai (défaut) retranche la moyenne ; faux
%                        analyse X tel quel, et MU est nul.
%      'Economy'         vrai (défaut) : quand il y a moins de degrés de
%                        liberté que de variables, seuls les axes porteurs
%                        de variance sont rendus.
%      'NumComponents'   le nombre d'axes rendus dans COEFF et SCORE.
%      'Rows'            'complete' (défaut) écarte les lignes portant
%                        un NaN, dont SCORE et TSQUARED valent NaN ;
%                        'all' refuse les NaN.
%      'VariableWeights' 'variance' réduit chaque variable : l'analyse
%                        porte alors sur la matrice de corrélation, et
%                        COEFF vaut DIAG(STD(X)) fois les axes
%                        orthonormés.
%   MatLibre refuse en le disant ce qu'il ne calcule pas : 'Weights', un
%   vecteur de 'VariableWeights', 'Rows','pairwise' et l'algorithme
%   'als'.
%
%   Exemple :
%      % Les données de Hald (1960) :
%      X = [7 26 6 60; 1 29 15 52; 11 56 8 20; 11 31 8 47; 7 52 6 33;
%           11 55 9 22; 3 71 17 6; 1 31 22 44; 2 54 18 22; 21 47 4 26;
%           1 40 23 34; 11 66 9 12; 10 68 8 12];
%      [coeff, ~, ~, t2, expliquee] = pca(X);
%      coeff(:, 1)'      % -0.0678 -0.6785 0.0290 0.7309
%      expliquee(1)      % 86.5974
%      t2(1)             % 5.6803
%
%   Voir aussi PCACOV, PCARES, CMDSCALE, FACTORAN, SVD.
    if ~isnumeric(X) && ~islogical(X)
        error('stats:pca:BadData', 'PCA attend une matrice numérique.');
    end
    if ~ismatrix(X)
        error('stats:pca:BadData', ...
              'PCA attend une matrice : une observation par ligne.');
    end
    classe = class(X);
    if ~strcmp(classe, 'single')
        classe = 'double';
    end
    X = double(X);
    [algorithme, centre, economie, nbAxes, lignes, poidsVariables] = lireOptions(varargin);

    [n, p] = size(X);
    manquantes = any(isnan(X), 2);
    if any(manquantes)
        if strcmp(lignes, 'all')
            error('stats:pca:RowsAll', ...
                  ['Rows,''all'' n''admet pas de NaN : écartez-les, ou laissez ' ...
                   'la valeur par défaut ''complete''.']);
        end
    end
    gardees = ~manquantes;
    Xg = X(gardees, :);
    ng = size(Xg, 1);

    if centre
        if ng > 0
            mu = mean(Xg, 1);
        else
            mu = nan(1, p);
        end
    else
        mu = zeros(1, p);
    end
    Xc = Xg - mu;
    dof = max(0, ng - centre);

    % Réduction des variables : on analyse X ./ ECARTTYPE, puis on rend
    % les coefficients dans l'unité des variables d'origine.
    racinePoids = ones(1, p);
    if ~isempty(poidsVariables)
        variances = var(Xg, 0, 1);
        if any(variances == 0)
            error('stats:pca:ZeroVariance', ...
                  ['VariableWeights,''variance'' : une variable est constante, ' ...
                   'elle ne peut être réduite.']);
        end
        racinePoids = 1 ./ sqrt(variances);
        Xc = Xc .* racinePoids;
    end

    if dof == 0
        coeff = zeros(p, 0);
        scoreG = zeros(ng, 0);
        latent = zeros(0, 1);
        if ~economie
            coeff = eye(p);
            scoreG = zeros(ng, p);
            latent = zeros(p, 1);
        end
    elseif strcmp(algorithme, 'svd')
        if economie
            [U, S, V] = svd(Xc, 'econ');
        else
            [U, S, V] = svd(Xc);
        end
        valeursSing = diag(S);
        coeff = V;
        scoreG = U(:, 1:numel(valeursSing)) .* valeursSing.';
        if size(coeff, 2) > numel(valeursSing)
            scoreG = [scoreG, zeros(ng, size(coeff, 2) - numel(valeursSing))];
        end
        latent = [valeursSing .^ 2; zeros(size(coeff, 2) - numel(valeursSing), 1)] / dof;
    else
        C = (Xc' * Xc) / dof;
        C = (C + C') / 2;
        [V, D] = eig(C);
        [latent, ordre] = sort(max(real(diag(D)), 0), 'descend');
        coeff = V(:, ordre);
        scoreG = Xc * coeff;
    end

    % Les axes au-delà des degrés de liberté ne portent rien.
    if dof < size(coeff, 2)
        if economie
            coeff = coeff(:, 1:dof);
            scoreG = scoreG(:, 1:dof);
            latent = latent(1:dof);
        else
            scoreG(:, dof + 1:end) = 0;
            latent(dof + 1:end) = 0;
        end
    end

    % Les coefficients dans l'unité des variables.
    if ~isempty(poidsVariables)
        coeff = coeff ./ racinePoids.';
    end

    % Convention de signe de MATLAB : le plus grand coefficient de chaque
    % axe, en valeur absolue, est positif.
    if ~isempty(coeff)
        [~, rangMax] = max(abs(coeff), [], 1);
        signes = sign(coeff(sub2ind(size(coeff), rangMax, 1:size(coeff, 2))));
        signes(signes == 0) = 1;
        coeff = coeff .* signes;
        scoreG = scoreG .* signes;
    end

    if nargout > 3
        tsquaredG = hotelling(scoreG, latent, dof, p);
        tsquared = nan(n, 1);
        tsquared(gardees) = tsquaredG;
    end
    if nargout > 4
        total = sum(latent);
        if total > 0
            explained = 100 * latent / total;
        else
            explained = zeros(size(latent));
        end
    end

    if ~isempty(nbAxes)
        if nbAxes > size(coeff, 2) && nbAxes > dof
            error('stats:pca:NumComponents', ...
                  ['NumComponents vaut au plus %d ici : c''est le nombre d''axes ' ...
                   'que portent les données.'], size(coeff, 2));
        end
        nbAxes = min(nbAxes, size(coeff, 2));
        coeff = coeff(:, 1:nbAxes);
        scoreG = scoreG(:, 1:nbAxes);
    end

    score = nan(n, size(scoreG, 2));
    score(gardees, :) = scoreG;

    if strcmp(classe, 'single')
        coeff = single(coeff);
        score = single(score);
        latent = single(latent);
        if nargout > 3, tsquared = single(tsquared); end
        if nargout > 4, explained = single(explained); end
        mu = single(mu);
    end
end

% Le T² de Hotelling : la somme des carrés des coordonnées réduites. Les
% axes sans variance — orthogonaux aux données — sont laissés de côté,
% comme le fait MATLAB.
function t2 = hotelling(score, latent, dof, p)
    if isempty(score)
        t2 = zeros(size(score, 1), 1);
        return
    end
    if dof > 1
        q = sum(latent > max(dof, p) * eps(latent(1)));
    else
        q = 0;
    end
    t2 = sum((score(:, 1:q) ./ sqrt(latent(1:q).')) .^ 2, 2);
end

function [algorithme, centre, economie, nbAxes, lignes, poidsVariables] = lireOptions(arguments)
    algorithme = 'svd';
    centre = true;
    economie = true;
    nbAxes = [];
    lignes = 'complete';
    poidsVariables = [];
    if mod(numel(arguments), 2) ~= 0
        error('stats:pca:BadNameValue', ...
              'PCA : les options vont par paires, un nom et une valeur.');
    end
    for k = 1:2:numel(arguments)
        nom = arguments{k};
        valeur = arguments{k + 1};
        if ~(ischar(nom) || (isstring(nom) && isscalar(nom)))
            error('stats:pca:BadNameValue', 'PCA : nom d''option attendu.');
        end
        switch lower(char(nom))
            case 'algorithm'
                algorithme = lower(char(valeur));
                if strcmp(algorithme, 'als')
                    error('stats:pca:NotSupported', ...
                          ['Algorithm,''als'' (moindres carrés alternés pour les ' ...
                           'données manquantes) n''est pas pris en charge par MatLibre.']);
                end
                if ~any(strcmp(algorithme, {'svd', 'eig'}))
                    error('stats:pca:BadAlgorithm', ...
                          'Algorithm vaut ''svd'' ou ''eig'', non ''%s''.', algorithme);
                end
            case 'centered'
                centre = logical(valeur);
            case 'economy'
                economie = logical(valeur);
            case 'numcomponents'
                if ~(isnumeric(valeur) && isscalar(valeur) && valeur >= 1 && ...
                     valeur == round(valeur))
                    error('stats:pca:BadNumComponents', ...
                          'NumComponents est un entier positif.');
                end
                nbAxes = double(valeur);
            case 'rows'
                lignes = lower(char(valeur));
                if strcmp(lignes, 'pairwise')
                    error('stats:pca:NotSupported', ...
                          ['Rows,''pairwise'' n''est pas pris en charge par MatLibre : ' ...
                           'employez ''complete'' (défaut).']);
                end
                if ~any(strcmp(lignes, {'complete', 'all'}))
                    error('stats:pca:BadRows', ...
                          'Rows vaut ''complete'' ou ''all'', non ''%s''.', lignes);
                end
            case 'variableweights'
                if (ischar(valeur) || isstring(valeur)) && strcmpi(char(valeur), 'variance')
                    poidsVariables = 'variance';
                else
                    error('stats:pca:NotSupported', ...
                          ['VariableWeights n''admet dans MatLibre que ''variance'' ; ' ...
                           'un vecteur de poids n''est pas pris en charge.']);
                end
            case 'weights'
                error('stats:pca:NotSupported', ...
                      ['Weights (poids des observations) n''est pas pris en charge ' ...
                       'par MatLibre.']);
            otherwise
                error('stats:pca:BadNameValue', 'PCA n''a pas d''option ''%s''.', char(nom));
        end
    end
end
