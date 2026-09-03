function modele = fitlme(donnees, formule, varargin)
%FITLME Modèle linéaire à effets mixtes.
%   M = FITLME(T,'y ~ 1 + x + (1|g)') ajuste un modèle où les effets de
%   x sont communs à toutes les observations — les effets fixes — tandis
%   que chaque niveau de g reçoit son propre décalage, tiré d'une loi
%   normale centrée : c'est l'effet aléatoire.
%
%   C'est ce qu'il faut quand les observations ne sont pas indépendantes
%   parce qu'elles se regroupent : plusieurs mesures par patient,
%   plusieurs élèves par classe. Un modèle ordinaire y sous-estimerait
%   les écarts types.
%
%   FITLME(...,'FitMethod','ML') estime par maximum de vraisemblance ;
%   'REML' (défaut) corrige le biais dû à l'estimation des effets fixes.
%
%   Le modèle rendu est une structure : Coefficients, SE, tStat, pValue,
%   Fitted, Residuals, SigmaB (écart type de l'effet aléatoire), Sigma
%   (écart type résiduel), LogLikelihood, AIC, BIC, RandomEffects.
%
%   MatLibre traite les intercepts aléatoires — la forme (1|g), la plus
%   courante —, avec un ou plusieurs facteurs de regroupement croisés.
%   Les pentes aléatoires, de la forme (x|g), ne sont pas ajustées.
%
%   L'estimation profile la vraisemblance sur le rapport des variances :
%   pour un rapport donné, les effets fixes s'obtiennent par moindres
%   carrés généralisés, et l'on cherche le rapport qui maximise ce qui
%   reste.
%
%   Exemple :
%      rng(1);
%      g = repmat((1:10)', 20, 1);
%      decalage = randn(10, 1) * 2;
%      x = randn(200, 1);
%      y = 1 + 3 * x + decalage(g) + 0.5 * randn(200, 1);
%      t = table(y, x, g);
%      m = fitlme(t, 'y ~ 1 + x + (1|g)');
%      m.SigmaB      % proche de 2
%
%   Voir aussi FITLM, FITGLM, ANOVAN, NLINFIT.
    methode = 'REML';
    k = 1;
    while k + 1 <= numel(varargin)
        switch lower(char(varargin{k}))
            case 'fitmethod', methode = upper(char(varargin{k+1}));
            case {'covariancepattern', 'dummyvarcoding', 'startmethod', 'verbose', ...
                  'checkhessian', 'optimizer'}
                % Acceptées et sans effet.
            otherwise
                error('stats:fitlme:Option', 'Option inconnue : %s.', char(varargin{k}));
        end
        k = k + 2;
    end
    [nomReponse, termesFixes, termesAleatoires] = lireFormuleMixte(char(formule));
    y = colonneDe(donnees, nomReponse);
    n = numel(y);
    X = ones(n, 0);
    nomsFixes = {};
    avecConstante = false;
    for t = 1:numel(termesFixes)
        if strcmp(termesFixes{t}, '1')
            avecConstante = true;
        elseif strcmp(termesFixes{t}, '-1') || strcmp(termesFixes{t}, '0')
            avecConstante = false;
        else
            X = [X, colonneDe(donnees, termesFixes{t})];   %#ok<AGROW>
            nomsFixes{end + 1} = termesFixes{t};           %#ok<AGROW>
        end
    end
    if avecConstante || isempty(termesFixes)
        X = [ones(n, 1), X];
        nomsFixes = [{'(Intercept)'}, nomsFixes];
    end
    if isempty(termesAleatoires)
        error('stats:fitlme:Aleatoire', ...
              'La formule doit porter au moins un terme aléatoire, comme (1|g).');
    end
    % Chaque facteur de regroupement donne un bloc d'indicatrices.
    Z = zeros(n, 0);
    blocs = zeros(1, numel(termesAleatoires));
    for t = 1:numel(termesAleatoires)
        facteur = colonneCategorielle(donnees, termesAleatoires{t});
        niveaux = unique(facteur);
        bloc = zeros(n, numel(niveaux));
        for j = 1:numel(niveaux)
            bloc(:, j) = double(facteur == niveaux(j));
        end
        Z = [Z, bloc];        %#ok<AGROW>
        blocs(t) = numel(niveaux);
    end
    reml = strcmp(methode, 'REML');
    % Un seul paramètre à chercher : le rapport de la variance des
    % effets aléatoires à celle du bruit. La recherche se fait sur son
    % logarithme, où la vraisemblance est bien conditionnée.
    objectif = @(logLambda) -logVraisemblanceProfilee(exp(logLambda), X, Z, y, reml);
    logLambda = fminbnd(objectif, -12, 12);
    lambda = exp(logLambda);
    [logv, beta, sigma2, covariance, effets] = ...
        logVraisemblanceProfilee(lambda, X, Z, y, reml);
    p = size(X, 2);
    erreurs = sqrt(max(diag(covariance), 0));
    t = beta ./ max(erreurs, eps);
    ddl = n - p;
    modele = struct('Coefficients', beta, 'CoefficientNames', {nomsFixes}, ...
                    'SE', erreurs, 'tStat', t, ...
                    'pValue', 2 * (1 - tcdf(abs(t), max(ddl, 1))), ...
                    'Fitted', X * beta + Z * effets, ...
                    'Residuals', y - X * beta - Z * effets, ...
                    'RandomEffects', effets, 'GroupSizes', blocs, ...
                    'Sigma', sqrt(sigma2), 'SigmaB', sqrt(lambda * sigma2), ...
                    'Lambda', lambda, 'LogLikelihood', logv, ...
                    'AIC', -2 * logv + 2 * (p + 2), ...
                    'BIC', -2 * logv + (p + 2) * log(n), ...
                    'NumObservations', n, 'FitMethod', methode, ...
                    'Formula', char(formule), 'DFE', max(ddl, 0));
end

function [logv, beta, sigma2, covariance, effets] = logVraisemblanceProfilee(lambda, X, Z, y, reml)
%LOGVRAISEMBLANCEPROFILEE Vraisemblance à rapport de variances fixé.
%   La covariance marginale vaut sigma^2 (I + lambda Z Z') ; on la
%   factorise une fois, et tout le reste — effets fixes, variance
%   résiduelle, déterminant — s'en déduit.
    [n, p] = size(X);
    q = size(Z, 2);
    % (I + lambda Z Z')^-1 = I - lambda Z (I + lambda Z'Z)^-1 Z' :
    % l'inversion porte sur q x q au lieu de n x n.
    M = eye(q) + lambda * (Z.' * Z);
    [R, defaut] = chol(M);
    if defaut ~= 0
        M = M + 1e-10 * eye(q);
        R = chol(M);
    end
    appliquerInverse = @(A) A - lambda * (Z * (M \ (Z.' * A)));
    Vx = appliquerInverse(X);
    Vy = appliquerInverse(y);
    A = X.' * Vx;
    beta = pinv(A) * (X.' * Vy);
    residu = y - X * beta;
    quadratique = residu.' * appliquerInverse(residu);
    % log|V| = log|I + lambda Z Z'| = log|I + lambda Z'Z|.
    logDeterminant = 2 * sum(log(diag(R)));
    if reml
        ddl = n - p;
        sigma2 = quadratique / max(ddl, 1);
        logv = -0.5 * (ddl * log(2 * pi * sigma2) + logDeterminant + quadratique / sigma2 ...
                       + log(max(det(A), realmin)));
    else
        ddl = n;
        sigma2 = quadratique / n;
        logv = -0.5 * (n * log(2 * pi * sigma2) + logDeterminant + quadratique / sigma2);
    end
    covariance = sigma2 * pinv(A);
    % Les effets aléatoires : leur espérance conditionnelle.
    effets = lambda * (M \ (Z.' * residu));
end

function [reponse, fixes, aleatoires] = lireFormuleMixte(formule)
%LIREFORMULEMIXTE Découpe « y ~ 1 + x + (1|g) ».
    morceaux = strsplit(formule, '~');
    if numel(morceaux) ~= 2
        error('stats:fitlme:Formule', 'La formule doit contenir un « ~ ».');
    end
    reponse = strtrim(morceaux{1});
    droite = strtrim(morceaux{2});
    fixes = {};
    aleatoires = {};
    termes = strsplit(droite, '+');
    for k = 1:numel(termes)
        terme = strtrim(termes{k});
        if isempty(terme)
            continue;
        end
        if terme(1) == '('
            interieur = strtrim(terme(2:end-1));
            barre = strfind(interieur, '|');
            if isempty(barre)
                error('stats:fitlme:Formule', ...
                      'Un terme aléatoire s''écrit (1|facteur).');
            end
            gauche = strtrim(interieur(1:barre(1)-1));
            if ~strcmp(gauche, '1')
                error('stats:fitlme:PenteAleatoire', ...
                      'MatLibre n''ajuste que les intercepts aléatoires : (1|facteur).');
            end
            aleatoires{end + 1} = strtrim(interieur(barre(1)+1:end));   %#ok<AGROW>
        else
            fixes{end + 1} = terme;   %#ok<AGROW>
        end
    end
end

function v = colonneDe(donnees, nom)
    if istable(donnees) || istimetable(donnees)
        v = double(donnees.(nom));
        v = v(:);
    elseif isstruct(donnees)
        v = double(donnees.(nom));
        v = v(:);
    else
        error('stats:fitlme:Donnees', 'FITLME attend une table.');
    end
end

function v = colonneCategorielle(donnees, nom)
% Un facteur de regroupement, ramené à des numéros de niveau.
    if istable(donnees) || istimetable(donnees)
        brut = donnees.(nom);
    else
        brut = donnees.(nom);
    end
    if iscell(brut) || ischar(brut) || isstring(brut) || iscategorical(brut)
        [~, ~, v] = unique(cellstr(brut));
    else
        [~, ~, v] = unique(double(brut(:)));
    end
    v = v(:);
end
