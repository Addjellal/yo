function modele = fitcdiscr(X, y, varargin)
%FITCDISCR Analyse discriminante.
%   M = FITCDISCR(X,Y) ajuste un classifieur par analyse discriminante
%   linéaire : chaque classe est supposée gaussienne, et toutes partagent
%   la même matrice de covariance.
%
%   FITCDISCR(...,'DiscrimType','quadratic') laisse à chaque classe sa
%   propre covariance ; la frontière entre deux classes devient une
%   quadrique au lieu d'un hyperplan.
%   FITCDISCR(...,'Prior',P) impose les probabilités a priori ;
%   'uniform' les égalise.
%   FITCDISCR(...,'Gamma',G) régularise la covariance en la rapprochant
%   d'une diagonale, ce qui la rend inversible quand les variables sont
%   peu nombreuses devant les dimensions.
%
%   PREDICT applique le modèle.
%
%   La règle est celle de Bayes, écrite pour des gaussiennes : on classe
%   x dans la classe qui maximise
%
%      log P(classe) + log densite(x | classe)
%
%   Quand les covariances sont communes, les termes quadratiques en x se
%   simplifient entre classes et il ne reste qu'une fonction affine — le
%   discriminant linéaire de Fisher. C'est ce qui distingue les deux
%   variantes : ce n'est pas le modèle qui change de nature, seulement ce
%   qui survit à la soustraction.
%
%   Exemple :
%      rng(1);
%      X = [randn(50, 2); randn(50, 2) + 3];
%      y = [ones(50, 1); 2 * ones(50, 1)];
%      m = fitcdiscr(X, y);
%      mean(predict(m, X) == y)
%
%   Voir aussi PREDICT, FITCNB, FITCSVM, FITCKNN, PCA.
    X = double(X);
    y = y(:);
    if size(X, 1) ~= numel(y)
        error('stats:fitcdiscr:Tailles', ...
              'X et Y doivent avoir le même nombre d''observations.');
    end
    [classes, ~, indices] = unique(y);
    k = numel(classes);
    if k < 2
        error('stats:fitcdiscr:Classes', ...
              'Il faut au moins deux classes.');
    end
    genre = 'linear';
    apriori = [];
    gamma = 0;
    j = 1;
    while j + 1 <= numel(varargin)
        switch lower(char(varargin{j}))
            case 'discrimtype'
                genre = lower(char(varargin{j + 1}));
            case 'prior'
                apriori = varargin{j + 1};
            case 'gamma'
                gamma = double(varargin{j + 1});
            case 'classnames'
                % Acceptée et sans effet.
            otherwise
                error('stats:fitcdiscr:Option', 'Option inconnue : %s.', ...
                      char(varargin{j}));
        end
        j = j + 2;
    end
    if ~any(strcmp(genre, {'linear', 'quadratic', 'diaglinear', 'diagquadratic'}))
        error('stats:fitcdiscr:Genre', 'DiscrimType inconnu : %s.', genre);
    end
    if gamma < 0 || gamma > 1
        error('stats:fitcdiscr:Gamma', 'Gamma doit être entre zéro et un.');
    end
    p = size(X, 2);
    moyennes = zeros(k, p);
    compte = zeros(k, 1);
    covariances = cell(k, 1);
    commune = zeros(p, p);
    for c = 1:k
        bloc = X(indices == c, :);
        compte(c) = size(bloc, 1);
        moyennes(c, :) = mean(bloc, 1);
        if compte(c) > 1
            covariances{c} = cov(bloc);
        else
            covariances{c} = zeros(p, p);
        end
        centre = bloc - moyennes(c, :);
        commune = commune + centre' * centre;
    end
    % Covariance commune : la somme des dispersions internes, divisée par
    % le nombre d'observations moins le nombre de classes. C'est
    % l'estimateur non biaisé quand les classes partagent leur forme.
    commune = commune / max(numel(y) - k, 1);
    quadratique = any(strcmp(genre, {'quadratic', 'diagquadratic'}));
    diagonale = any(strcmp(genre, {'diaglinear', 'diagquadratic'}));
    if quadratique
        for c = 1:k
            covariances{c} = regulariser(covariances{c}, gamma, diagonale);
        end
    else
        commune = regulariser(commune, gamma, diagonale);
        for c = 1:k
            covariances{c} = commune;
        end
    end
    if isempty(apriori)
        apriori = compte / sum(compte);
    elseif ischar(apriori) || isstring(apriori)
        if ~strcmpi(char(apriori), 'uniform')
            error('stats:fitcdiscr:Apriori', ...
                  'Prior vaut ''uniform'' ou un vecteur.');
        end
        apriori = ones(k, 1) / k;
    else
        apriori = double(apriori(:));
        apriori = apriori / sum(apriori);
    end
    modele = struct('type', 'discriminant', 'Classes', {classes}, ...
                    'DiscrimType', genre, 'Mu', moyennes, ...
                    'Sigma', {covariances}, 'CommuneSigma', commune, ...
                    'Prior', apriori, 'NumObservations', numel(y));
end

function S = regulariser(S, gamma, diagonale)
%REGULARISER Rapprochement de la covariance d'une diagonale.
%   Une covariance estimée sur peu d'observations est mal conditionnée,
%   voire singulière. La tirer vers sa diagonale la rend inversible sans
%   changer les variances, seulement les corrélations.
    if diagonale
        S = diag(diag(S));
    elseif gamma > 0
        S = (1 - gamma) * S + gamma * diag(diag(S));
    end
    % Un plancher sur la diagonale évite l'inversion d'une matrice
    % exactement singulière quand une variable est constante.
    plancher = 1e-12 * max(1, mean(diag(S)));
    S = S + plancher * eye(size(S));
end
