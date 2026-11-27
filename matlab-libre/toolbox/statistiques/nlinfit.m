function [beta, residus, jacobienne, covariance, erreurQuadratique, infoErreur] = ...
    nlinfit(X, y, modele, beta0, varargin)
%NLINFIT Ajustement d'un modèle non linéaire par moindres carrés.
%   BETA = NLINFIT(X,Y,MODELE,BETA0) cherche les paramètres BETA qui
%   rendent MODELE(BETA,X) le plus proche de Y au sens des moindres
%   carrés, en partant de BETA0. MODELE est une poignée de fonction dont
%   le premier argument est le vecteur des paramètres et le second les
%   données ; elle rend un vecteur de la taille de Y. BETA est rendu en
%   colonne.
%
%   La minimisation est celle de Levenberg-Marquardt (Marquardt, 1963) :
%   chaque pas résout le problème linéarisé amorti
%      min |J*pas - r|^2 + lambda*|D*pas|^2,   D = normes des colonnes de J,
%   par une factorisation QR du système augmenté — sans former J'*J, dont
%   le conditionnement est le carré de celui de J. L'amortissement lambda
%   part de 0,01, est divisé par dix après un pas qui fait baisser la
%   somme des carrés et multiplié par dix tant qu'il la fait monter. La
%   jacobienne est estimée par différences centrées.
%
%   L'ajustement s'arrête quand le pas devient petit devant BETA
%   (norme du pas < TolX*(sqrt(eps)+norme de BETA)) ou quand la somme des
%   carrés ne bouge plus (variation <= TolFun*SSE, une tolérance
%   relative). Les observations où Y vaut NaN sont ignorées.
%
%   [BETA,R] = NLINFIT(...) rend les résidus Y - MODELE(BETA,X).
%   [BETA,R,J] = NLINFIT(...) rend la jacobienne du modèle en BETA.
%   [BETA,R,J,COVB] = NLINFIT(...) rend la covariance estimée des
%   paramètres, MSE*inv(J'*J), dont NLPARCI tire les intervalles.
%   [BETA,R,J,COVB,MSE] = NLINFIT(...) rend la variance résiduelle
%   SSE/(N-P).
%   [...,INFO] = NLINFIT(...) rend la structure du modèle d'erreur :
%   ErrorModel 'constant', ErrorParameters, ErrorVariance, MSE,
%   ScheffeSimPred, WeightFunction, WeightVectorDerivative,
%   RobustWeightFunction, FixedWeights, RobustWeights.
%
%   NLINFIT(...,OPTIONS) prend une structure de STATSET :
%      MaxIter     nombre maximal d'itérations (100)
%      TolFun      tolérance relative sur la somme des carrés (1e-8)
%      TolX        tolérance relative sur le pas (1e-8)
%      DerivStep   pas relatif des différences finies (eps^(1/3))
%      Display     'off', 'final' ou 'iter'
%      FunValCheck 'on' : refuse un modèle qui rend Inf ou NaN au départ
%   STATSET('nlinfit') rend ces valeurs par défaut.
%
%   Quand le résultat est douteux, NLINFIT le dit, comme MATLAB, par un
%   avertissement : limite d'itérations atteinte, aucun pas qui fasse
%   baisser la somme des carrés, modèle insensible à un paramètre
%   (colonne nulle de la jacobienne — souvent un départ mal choisi qui
%   envoie un paramètre à l'infini), jacobienne mal conditionnée,
%   modèle surparamétré (pas plus d'observations que de paramètres).
%
%   L'ajustement robuste (Robust 'on'), les poids ('Weights') et les
%   modèles d'erreur autres que 'constant' ne sont pas faits : NLINFIT
%   le dit au lieu d'ajuster autre chose que ce qui est demandé.
%
%   Exemples :
%      x = (0:0.2:5)';
%      y = 2.5 * exp(-0.8 * x) + 0.01 * cos(7 * x);
%      beta = nlinfit(x, y, @(b, t) b(1) * exp(-b(2) * t), [1; 1])
%      % proche de [2.5 ; 0.8]
%
%      [b, r, J, covb] = nlinfit(x, y, @(b, t) b(1) * exp(-b(2) * t), [1; 1]);
%      nlparci(b, r, 'covar', covb)
%
%      options = statset('nlinfit');
%      options.TolFun = 1e-12;
%      beta = nlinfit(x, y, @(b, t) b(1) * exp(-b(2) * t), [1; 1], options);
%
%   Voir aussi STATSET, NLPARCI, LSQCURVEFIT, FITLM, REGRESS, POLYFIT.
    [options, modeleErreur] = lireArguments(varargin);
    if ~isa(modele, 'function_handle')
        error('stats:nlinfit:BadModel', 'MODELFUN must be a function handle.');
    end
    if ~isnumeric(beta0) || isempty(beta0) || ~isvector(beta0)
        error('stats:nlinfit:BadBeta0', 'BETA0 must be a numeric vector.');
    end
    if ~strcmpi(modeleErreur, 'constant')
        error('stats:nlinfit:ErrorModelNotSupported', ...
              ['NLINFIT: error model ''%s'' is not supported; ', ...
               'only ''constant'' is.'], modeleErreur);
    end
    if strcmpi(options.Robust, 'on')
        error('stats:nlinfit:RobustNotSupported', ...
              ['NLINFIT: robust fitting (Robust ''on'') is not ', ...
               'supported. ROBUSTFIT does it for a linear model.']);
    end
    y = double(y(:));
    beta = double(beta0(:));
    p = numel(beta);
    yAjuste = evaluer(modele, beta, X, numel(y));
    if strcmpi(options.FunValCheck, 'on') && any(isinf(yAjuste))
        error('stats:nlinfit:NonFiniteFunOutput', ...
              'MODELFUN has returned Inf or NaN values.');
    end
    % Une observation manquante — NaN dans Y ou dans le modèle au
    % départ — ne compte pas, comme dans MATLAB.
    garde = ~isnan(y) & ~isnan(yAjuste);
    if ~any(garde)
        error('stats:nlinfit:NoUsableData', ...
              'No observations without NaN remain.');
    end
    [beta, cause, iterations] = levenbergMarquardt(modele, X, y, beta, garde, options);
    switch cause
        case 'maxiter'
            warning('stats:nlinfit:IterationLimitExceeded', ...
                    'Iteration limit exceeded.  Returning results from final iteration.');
        case 'stall'
            warning('stats:nlinfit:UnableToDecreaseSSE', ...
                    ['Unable to find a step that will decrease SSE.  ', ...
                     'Returning results from last iteration.']);
    end
    if strcmpi(options.Display, 'final') || strcmpi(options.Display, 'iter')
        afficherArret(cause, iterations);
    end

    residus = y - evaluer(modele, beta, X, numel(y));
    jacobienne = jacobienneNumerique(modele, beta, X, numel(y), options.DerivStep);
    Jg = jacobienne(garde, :);
    rg = residus(garde);
    n = numel(rg);
    sse = rg' * rg;
    signalerJacobienne(Jg, n, p);
    erreurQuadratique = sse / max(n - p, 1);
    if n > p
        [~, R] = qr(Jg, 0);
        Rinv = R \ eye(p);
        covariance = erreurQuadratique * (Rinv * Rinv');
    else
        covariance = nan(p);
    end
    if nargout > 5
        infoErreur = struct('ErrorModel', 'constant', ...
            'ErrorParameters', sqrt(erreurQuadratique), ...
            'ErrorVariance', @(x) erreurQuadratique * ones(size(x, 1), 1), ...
            'MSE', erreurQuadratique, 'ScheffeSimPred', p, ...
            'WeightFunction', false, 'WeightVectorDerivative', [], ...
            'RobustWeightFunction', false, 'FixedWeights', false, ...
            'RobustWeights', []);
    end
end

function [beta, cause, iteration] = levenbergMarquardt(modele, X, y, beta, garde, options)
%LEVENBERGMARQUARDT Le cœur de l'ajustement : pas amortis jusqu'à l'arrêt.
    p = numel(beta);
    n = numel(y);
    r = y - evaluer(modele, beta, X, n);
    r = r(garde);
    sse = r' * r;
    lambda = 0.01;
    cause = '';
    iteration = 0;
    if strcmpi(options.Display, 'iter')
        fprintf('\n%12s %18s %16s %16s\n', 'Itération', 'SSE', 'Norme du gradient', ...
                'Norme du pas');
        fprintf('%12d %18.6g\n', 0, sse);
    end
    while iteration < options.MaxIter
        iteration = iteration + 1;
        ancienBeta = beta;
        ancienneSse = sse;
        J = jacobienneNumerique(modele, beta, X, n, options.DerivStep);
        J = J(garde, :);
        % La mise à l'échelle de Marquardt : chaque paramètre est amorti à
        % proportion de la sensibilité du modèle à ce paramètre. Résoudre
        % en variables réduites garde le système augmenté de plein rang,
        % même quand une colonne de J est nulle.
        echelle = sqrt(sum(J .^ 2, 1))';
        echelle(echelle == 0 | ~isfinite(echelle)) = 1;
        Jr = J ./ echelle';
        bloque = false;
        while true
            reduit = [Jr; sqrt(lambda) * eye(p)] \ [r; zeros(p, 1)];
            pas = reduit ./ echelle;
            beta = ancienBeta + pas;
            rEssai = y - evaluer(modele, beta, X, n);
            rEssai = rEssai(garde);
            sseEssai = rEssai' * rEssai;
            if isfinite(sseEssai) && sseEssai <= ancienneSse
                r = rEssai;
                sse = sseEssai;
                break
            end
            lambda = 10 * lambda;
            if lambda > 1e16
                % Plus aucun pas ne fait baisser la somme des carrés : on
                % reste au dernier point.
                beta = ancienBeta;
                pas = zeros(p, 1);
                bloque = true;
                break
            end
        end
        if ~bloque
            lambda = max(lambda / 10, eps);
        end
        if strcmpi(options.Display, 'iter')
            fprintf('%12d %18.6g %16.4g %16.4g\n', iteration, sse, norm(J' * r), norm(pas));
        end
        if bloque
            cause = 'stall';
            break
        end
        if norm(pas) < options.TolX * (sqrt(eps) + norm(beta))
            cause = 'tolx';
            break
        end
        if abs(sse - ancienneSse) <= options.TolFun * sse
            cause = 'tolfun';
            break
        end
    end
    if isempty(cause)
        cause = 'maxiter';
    end
end

function v = evaluer(modele, beta, X, n)
%EVALUER Le modèle en colonne, de la taille des observations.
    v = modele(beta, X);
    if numel(v) ~= n
        error('stats:nlinfit:WrongSizeFunOutput', ...
              'MODELFUN should return a vector of fitted values the same length as Y.');
    end
    v = double(v(:));
end

function J = jacobienneNumerique(modele, beta, X, n, pasRelatif)
%JACOBIENNENUMERIQUE Dérivées du modèle par différences centrées.
%   Le pas est pasRelatif*|beta(j)| (pasRelatif si beta(j) est nul) : le
%   choix eps^(1/3) équilibre l'erreur de troncature, en pas^2, et celle
%   d'arrondi, en eps/pas.
    p = numel(beta);
    J = zeros(n, p);
    for j = 1:p
        pas = pasRelatif * abs(beta(j));
        if pas == 0
            pas = pasRelatif;
        end
        avant = beta;
        apres = beta;
        avant(j) = avant(j) - pas;
        apres(j) = apres(j) + pas;
        J(:, j) = (evaluer(modele, apres, X, n) - evaluer(modele, avant, X, n)) / ...
                  (apres(j) - avant(j));
    end
end

function signalerJacobienne(J, n, p)
%SIGNALERJACOBIENNE Ce que la jacobienne au point trouvé dit de sa fiabilité.
    normes = sqrt(sum(J .^ 2, 1));
    if any(normes <= sqrt(eps) * max([normes, realmin]))
        warning('stats:nlinfit:ModelConstantWRTParam', ...
                ['Some columns of the Jacobian are effectively zero at the solution, ', ...
                 'indicating that the model is insensitive to some of its parameters.  ', ...
                 'That may be because those parameters are not present in the model, ', ...
                 'or otherwise do not affect the predicted values.  It may also be due ', ...
                 'to numerical underflow in the model function, which can sometimes be ', ...
                 'avoided by choosing better initial parameter values, or by rescaling ', ...
                 'or recentering.  Parameter estimates may be unreliable.']);
    elseif n <= p
        warning('stats:nlinfit:Overparameterized', ...
                ['The model is overparameterized, and model parameters are not ', ...
                 'identifiable.  You will not be able to compute confidence or ', ...
                 'prediction intervals, and you should use caution in making predictions.']);
    elseif cond(J) > 1 / sqrt(eps)
        warning('stats:nlinfit:IllConditionedJacobian', ...
                ['The Jacobian at the solution is ill-conditioned, and some model ', ...
                 'parameters may not be estimated well (they are not identifiable).  ', ...
                 'Use caution in making predictions.']);
    end
end

function afficherArret(cause, iterations)
    switch cause
        case 'tolx'
            texte = 'Norm of step is less than OPTIONS.TolX.';
        case 'tolfun'
            texte = 'Relative change in SSE less than OPTIONS.TolFun.';
        case 'stall'
            texte = 'Unable to find a step that will decrease SSE.';
        otherwise
            texte = 'Iteration limit exceeded.';
    end
    fprintf('%s (%d itérations)\n', texte, iterations);
end

function [options, modeleErreur] = lireArguments(arguments)
%LIREARGUMENTS La structure d'options, puis les paires nom-valeur.
    options = statset('nlinfit');
    modeleErreur = 'constant';
    k = 1;
    if ~isempty(arguments) && (isstruct(arguments{1}) || isempty(arguments{1}))
        if isstruct(arguments{1})
            donnees = arguments{1};
            noms = fieldnames(donnees);
            for i = 1:numel(noms)
                if ~isempty(donnees.(noms{i}))
                    options.(noms{i}) = donnees.(noms{i});
                end
            end
        end
        k = 2;
    end
    while k <= numel(arguments)
        if k == numel(arguments) || ~(ischar(arguments{k}) || isstring(arguments{k}))
            error('stats:nlinfit:BadArgs', ...
                  'NLINFIT options must be name-value pairs.');
        end
        nom = lower(char(arguments{k}));
        valeur = arguments{k + 1};
        switch nom
            case 'options'
                options = lireArguments({valeur});
            case 'errormodel'
                modeleErreur = char(valeur);
            case 'errorparameters'
                % sans objet pour le modèle 'constant'
            case 'weights'
                error('stats:nlinfit:WeightsNotSupported', ...
                      ['NLINFIT: observation weights (''Weights'') are ', ...
                       'not supported. LSQCURVEFIT fitting sqrt(w).*MODEL against ', ...
                       'sqrt(w).*Y is equivalent.']);
            otherwise
                error('stats:nlinfit:BadParamName', ...
                      'Unknown parameter name ''%s''.', char(arguments{k}));
        end
        k = k + 2;
    end
end
