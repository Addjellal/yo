classdef LinearModel
%LINEARMODEL Modèle de régression linéaire, tel que le rend FITLM.
%   Un LinearModel porte les propriétés de celui de MATLAB :
%      Coefficients         table : Estimate, SE, tStat, pValue, une ligne
%                           par coefficient, nommée comme lui
%      CoefficientNames, CoefficientCovariance, NumCoefficients,
%      NumEstimatedCoefficients (moins que NumCoefficients quand les
%                           termes sont liés : les coefficients de trop
%                           valent zéro, sans écart type)
%      Rsquared             structure : Ordinary (SSR/SST) et Adjusted
%      RMSE, MSE, SSE, SSR, SST, DFE
%      LogLikelihood        sous l'hypothèse d'erreurs normales de
%                           variance MSE
%      ModelCriterion       structure : AIC, AICc, BIC, CAIC, avec pour
%                           nombre de paramètres NumEstimatedCoefficients
%      Fitted, Residuals    table : Raw, Pearson, Studentized, Standardized
%      Diagnostics          table : Leverage, CooksDistance, Dffits, S2_i,
%                           CovRatio, Dfbetas (MatLibre ne range pas
%                           HatMatrix, une matrice N×N)
%      Formula              un objet CLASSREG.REGR.LINEARFORMULA
%      NumObservations, NumPredictors, NumVariables, ObservationInfo,
%      ObservationNames, PredictorNames, ResponseName, VariableNames,
%      Variables, VariableInfo
%   Les lignes écartées (valeur manquante, option Exclude) ont des
%   résidus NaN.
%
%   Méthodes : PREDICT (avec intervalles de confiance ou de prédiction,
%   ponctuels ou simultanés), FEVAL, RANDOM, COEFCI, COEFTEST, ANOVA,
%   DISP. MatLibre n'a pas encore les méthodes graphiques (PLOT,
%   PLOTRESIDUALS...) ni STEP, ADDTERMS, REMOVETERMS.
%
%   LINEARMODEL.FIT(...) est le nom ancien de FITLM.
%
%   Exemple :
%      x = (1:10)';
%      y = 2 + 3 * x + 0.1 * sin(x);
%      mdl = fitlm(x, y);
%      mdl.Coefficients.Estimate'     % proche de [2 3]
%      predict(mdl, 11)               % proche de 35
%
%   Voir aussi FITLM, CLASSREG.REGR.LINEARFORMULA, REGRESS, FITGLM.
    properties (SetAccess = private)
        Coefficients = []
        CoefficientCovariance = []
        CoefficientNames = {}
        NumCoefficients = 0
        NumEstimatedCoefficients = 0
        DFE = 0
        SSE = 0
        SSR = 0
        SST = 0
        MSE = 0
        RMSE = 0
        Rsquared = struct('Ordinary', 0, 'Adjusted', 0)
        LogLikelihood = 0
        ModelCriterion = struct('AIC', 0, 'AICc', 0, 'BIC', 0, 'CAIC', 0)
        Fitted = []
        Residuals = []
        Diagnostics = []
        Formula = []
        NumObservations = 0
        NumPredictors = 0
        NumVariables = 0
        ObservationInfo = []
        ObservationNames = {}
        PredictorNames = {}
        ResponseName = ''
        VariableNames = {}
        Variables = []
        VariableInfo = []
        Robust = []
        Steps = []
    end
    properties (SetAccess = private, Hidden)
        % Ce qu'il faut pour refaire la matrice de conception sur de
        % nouvelles données.
        Termes = zeros(0, 0)
        EstCategorielle = false(1, 0)
        Niveaux = {}
        Estimes = false(0, 1)
        AvecConstante = true
        Beta = zeros(0, 1)
    end

    methods
        function mdl = LinearModel(champs)
            if nargin == 0
                return
            end
            noms = fieldnames(champs);
            for k = 1:numel(noms)
                mdl.(noms{k}) = champs.(noms{k});
            end
        end

        function [ypred, yci] = predict(mdl, Xnouveau, varargin)
            %PREDICT Réponse prédite pour de nouvelles observations.
            %   YPRED = PREDICT(MDL,XNEW) : XNEW a une colonne par
            %   prédicteur, dans l'ordre de PredictorNames, ou c'est une
            %   table qui porte ces variables.
            %   [YPRED,YCI] = PREDICT(...) rend aussi un intervalle à 95 % :
            %      'Alpha',A             niveau 1-A ;
            %      'Prediction',P        'curve' (défaut) pour la réponse
            %                            moyenne, 'observation' pour une
            %                            nouvelle mesure, bruit compris ;
            %      'Simultaneous',S      vrai : bornes de Scheffé, valables
            %                            pour toutes les prédictions à la
            %                            fois.
            alpha = 0.05;
            observation = false;
            simultane = false;
            if mod(numel(varargin), 2) ~= 0
                error('stats:LinearModel:predict:BadNameValue', ...
                      'PREDICT : les options vont par paires, un nom et une valeur.');
            end
            for k = 1:2:numel(varargin)
                valeur = varargin{k + 1};
                switch lower(char(varargin{k}))
                    case 'alpha'
                        alpha = double(valeur);
                        if ~(isscalar(alpha) && alpha > 0 && alpha < 1)
                            error('stats:LinearModel:predict:BadAlpha', ...
                                  'Alpha est un nombre entre zéro et un.');
                        end
                    case 'prediction'
                        observation = strcmpi(char(valeur), 'observation');
                        if ~observation && ~strcmpi(char(valeur), 'curve')
                            error('stats:LinearModel:predict:BadPrediction', ...
                                  'Prediction vaut ''curve'' ou ''observation''.');
                        end
                    case 'simultaneous'
                        simultane = logical(valeur);
                    otherwise
                        error('stats:LinearModel:predict:BadNameValue', ...
                              'PREDICT n''a pas d''option ''%s''.', char(varargin{k}));
                end
            end
            D = conceptionNouvelle(mdl, Xnouveau);
            ypred = D * mdl.Beta;
            if nargout > 1
                variance = sum((D * mdl.CoefficientCovariance) .* D, 2);
                if observation
                    variance = variance + mdl.MSE;
                end
                p = mdl.NumEstimatedCoefficients;
                if simultane
                    if observation && ~mdl.AvecConstante
                        nombre = p + 1;
                    else
                        nombre = p;
                    end
                    critique = sqrt(nombre * finv(1 - alpha, nombre, mdl.DFE));
                else
                    critique = tinv(1 - alpha / 2, mdl.DFE);
                end
                demi = critique * sqrt(variance);
                yci = [ypred - demi, ypred + demi];
            end
        end

        function y = feval(mdl, varargin)
            %FEVAL Réponse prédite, les prédicteurs donnés un par un.
            %   Y = FEVAL(MDL,X1,X2,...) ou FEVAL(MDL,XNEW).
            if numel(varargin) == 1
                y = predict(mdl, varargin{1});
                return
            end
            if numel(varargin) ~= mdl.NumPredictors
                error('stats:LinearModel:feval:BadNumArgs', ...
                      'FEVAL attend un argument par prédicteur (%d).', mdl.NumPredictors);
            end
            colonnes = varargin;
            n = max(cellfun(@(c) size(c, 1) * (~ischar(c)) + ischar(c), colonnes));
            for k = 1:numel(colonnes)
                c = colonnes{k};
                if ~ischar(c) && size(c, 1) == 1 && n > 1
                    c = repmat(c, n, 1);
                end
                colonnes{k} = c;
            end
            t = table(colonnes{:}, 'VariableNames', mdl.PredictorNames);
            y = predict(mdl, t);
        end

        function ysim = random(mdl, Xnouveau)
            %RANDOM Réponses simulées : la prédiction plus un bruit normal
            %   d'écart type RMSE.
            ypred = predict(mdl, Xnouveau);
            ysim = ypred + mdl.RMSE * randn(size(ypred));
        end

        function ic = coefCI(mdl, alpha)
            %COEFCI Intervalles de confiance des coefficients.
            %   CI = COEFCI(MDL) rend les bornes à 95 % ; COEFCI(MDL,ALPHA)
            %   au niveau 1-ALPHA. Une ligne par coefficient.
            if nargin < 2
                alpha = 0.05;
            end
            t = tinv(1 - alpha / 2, mdl.DFE);
            se = mdl.Coefficients.SE;
            ic = [mdl.Beta - t * se, mdl.Beta + t * se];
        end

        function [p, F, r] = coefTest(mdl, H, c)
            %COEFTEST Test F d'hypothèses linéaires sur les coefficients.
            %   P = COEFTEST(MDL) teste la nullité de tous les coefficients
            %   hors la constante : c'est le F du modèle contre le modèle
            %   constant.
            %   P = COEFTEST(MDL,H) teste H*B = 0 ; COEFTEST(MDL,H,C) teste
            %   H*B = C. [P,F,R] rend aussi la statistique et son nombre de
            %   degrés de liberté au numérateur.
            k = mdl.NumCoefficients;
            if nargin < 2 || isempty(H)
                garder = mdl.Estimes(:).';
                if mdl.AvecConstante
                    garder(strcmp(mdl.CoefficientNames, '(Intercept)')) = false;
                end
                I = eye(k);
                H = I(garder, :);
            end
            if size(H, 2) ~= k
                error('stats:LinearModel:coefTest:BadH', ...
                      'H compte une colonne par coefficient (%d).', k);
            end
            if nargin < 3 || isempty(c)
                c = zeros(size(H, 1), 1);
            end
            ecart = H * mdl.Beta - c(:);
            V = H * mdl.CoefficientCovariance * H';
            r = rank(V);
            F = (ecart' * pinv(V) * ecart) / r;
            p = fcdf(F, r, mdl.DFE, 'upper');
        end

        function tbl = anova(mdl, genre, typeSomme)
            %ANOVA Analyse de la variance du modèle.
            %   TBL = ANOVA(MDL) ou ANOVA(MDL,'component') : une ligne par
            %   terme (hors constante) et une ligne Error, colonnes SumSq,
            %   DF, MeanSq, F, pValue. ANOVA(MDL,'component',SSTYPE) choisit
            %   les sommes de carrés : 'h' (défaut, hiérarchiques : un terme
            %   est jugé sans ceux qui le contiennent), 1 (séquentielles) ou
            %   3 (chaque terme après tous les autres).
            %   TBL = ANOVA(MDL,'summary') : lignes Total, Model, Residual.
            if nargin < 2 || isempty(genre)
                genre = 'component';
            end
            if nargin < 3 || isempty(typeSomme)
                typeSomme = 'h';
            end
            genre = lower(char(genre));
            switch genre
                case {'component', 'components'}
                    tbl = anovaComposantes(mdl, typeSomme);
                case 'summary'
                    sommes = [mdl.SST; mdl.SSR; mdl.SSE];
                    dfModele = mdl.NumEstimatedCoefficients - mdl.AvecConstante;
                    ddl = [mdl.NumObservations - mdl.AvecConstante; dfModele; mdl.DFE];
                    moyennes = sommes ./ ddl;
                    F = [NaN; moyennes(2) / mdl.MSE; NaN];
                    p = [NaN; fcdf(F(2), dfModele, mdl.DFE, 'upper'); NaN];
                    tbl = table(sommes, ddl, moyennes, F, p, ...
                                'VariableNames', {'SumSq', 'DF', 'MeanSq', 'F', 'pValue'}, ...
                                'RowNames', {'Total'; 'Model'; 'Residual'});
                otherwise
                    error('stats:LinearModel:anova:BadType', ...
                          'ANOVA : ''component'' ou ''summary'', non ''%s''.', genre);
            end
        end

        function disp(mdl)
            fprintf('Linear regression model:\n    %s\n\n', char(mdl.Formula));
            fprintf('Estimated Coefficients:\n');
            disp(mdl.Coefficients);
            fprintf('\nNumber of observations: %d, Error degrees of freedom: %d\n', ...
                    mdl.NumObservations, mdl.DFE);
            fprintf('Root Mean Squared Error: %.3g\n', mdl.RMSE);
            p = mdl.NumEstimatedCoefficients;
            if mdl.AvecConstante && p > 1
                fprintf('R-squared: %.3g,  Adjusted R-Squared: %.3g\n', ...
                        mdl.Rsquared.Ordinary, mdl.Rsquared.Adjusted);
                [pv, F] = coefTest(mdl);
                fprintf('F-statistic vs. constant model: %.3g, p-value = %.3g\n', F, pv);
            elseif ~mdl.AvecConstante && p > 0
                fprintf('R-squared: %.3g,  Adjusted R-Squared: %.3g\n', ...
                        mdl.Rsquared.Ordinary, mdl.Rsquared.Adjusted);
                [pv, F] = coefTest(mdl);
                fprintf('F-statistic vs. zero model: %.3g, p-value = %.3g\n', F, pv);
            end
        end

        function plot(~, varargin)
            error('stats:LinearModel:plot:NotSupported', ...
                  ['LinearModel/plot n''est pas encore pris en charge par MatLibre : ' ...
                   'tracez mdl.Fitted et mdl.Residuals.Raw.']);
        end
    end

    methods (Static)
        function mdl = fit(varargin)
            %FIT Nom ancien de FITLM.
            mdl = ajusterModele(varargin{:});
        end
    end
end

% ======================================================================
% Ajustement
% ======================================================================

function mdl = ajusterModele(varargin)
    if nargin < 1
        error('stats:fitlm:TooFewInputs', 'FITLM attend des données.');
    end
    e = lireEntrees(varargin);
    n = e.n;
    nomsVariables = e.noms;
    nVar = numel(nomsVariables);

    % --- les termes ------------------------------------------------------
    [termes, iReponse] = termesDuModele(e);
    termes = trierTermes(termes);
    if ~e.avecConstante
        termes = termes(any(termes > 0, 2), :);
    end
    utilisees = any(termes > 0, 1);
    utilisees(iReponse) = false;
    if any(termes(:, iReponse) > 0)
        error('stats:fitlm:ResponseInTerms', ...
              'La réponse %s ne peut figurer parmi les termes.', nomsVariables{iReponse});
    end
    if e.estCat(iReponse)
        error('stats:fitlm:BadResponse', ...
              'La réponse %s doit être numérique.', nomsVariables{iReponse});
    end
    for v = find(e.estCat)
        if any(termes(:, v) > 1)
            error('stats:fitlm:CategoricalPower', ...
                  'La variable catégorielle %s ne peut être élevée à une puissance.', ...
                  nomsVariables{v});
        end
    end
    if isempty(e.iPredicteurs)
        iPredicteurs = find(utilisees);
    else
        iPredicteurs = e.iPredicteurs;
        if any(utilisees & ~ismember(1:nVar, iPredicteurs))
            iPredicteurs = sort(unique([iPredicteurs(:).', find(utilisees)]));
        end
    end

    % --- valeurs manquantes, exclusions, poids --------------------------
    y = double(e.donnees{iReponse});
    y = y(:);
    manquantes = isnan(y);
    niveaux = cell(1, nVar);
    rangs = cell(1, nVar);
    for v = find(utilisees)
        if e.estCat(v)
            [niveaux{v}, rangs{v}, absent] = niveauxDe(e.donnees{v}, {});
            manquantes = manquantes | absent;
        else
            colonne = double(e.donnees{v});
            manquantes = manquantes | isnan(colonne(:));
        end
    end
    poids = e.poids;
    manquantes = manquantes | isnan(poids);
    exclues = e.exclues;
    sousEnsemble = ~manquantes & ~exclues;
    % Les niveaux sont ceux que porte l'ajustement.
    for v = find(utilisees & e.estCat)
        [niveaux{v}, rangs{v}] = niveauxDe(e.donnees{v}, {}, sousEnsemble);
    end

    [D, nomsCoef] = conception(termes, e.donnees, e.estCat, niveaux, rangs, nomsVariables);
    k = size(D, 2);
    nObs = sum(sousEnsemble);

    % --- moindres carrés pondérés, par QR pivotée -------------------------
    w = poids(sousEnsemble);
    racine = sqrt(w);
    Xw = D(sousEnsemble, :) .* racine;
    yw = y(sousEnsemble) .* racine;
    if isempty(Xw) || k == 0
        rang = 0;
        perm = 1:k;
        Q = zeros(nObs, 0);
        R = zeros(0, 0);
    else
        [Q, R, perm] = qr(Xw, 0);
        diagonale = abs(diag(R));
        if isempty(diagonale)
            rang = 0;
        else
            rang = sum(diagonale > max(size(Xw)) * eps(diagonale(1)));
        end
    end
    estimes = false(k, 1);
    estimes(perm(1:rang)) = true;
    beta = zeros(k, 1);
    Qr = Q(:, 1:rang);
    Rr = R(1:rang, 1:rang);
    if rang > 0
        beta(perm(1:rang)) = Rr \ (Qr' * yw);
        RrInv = Rr \ eye(rang);
    else
        RrInv = zeros(0, 0);
    end

    ajuste = D * beta;
    residus = y - ajuste;
    residus(~sousEnsemble) = NaN;
    rs = residus(sousEnsemble);
    sse = sum(w .* rs .^ 2);
    dfe = nObs - rang;
    mse = sse / dfe;
    ybarre = sum(w .* y(sousEnsemble)) / sum(w);
    sst = sum(w .* (y(sousEnsemble) - ybarre) .^ 2);
    ssr = sum(w .* (ajuste(sousEnsemble) - ybarre) .^ 2);
    covariance = zeros(k);
    covariance(perm(1:rang), perm(1:rang)) = (RrInv * RrInv') * mse;
    se = sqrt(max(diag(covariance), 0));
    tStat = beta ./ se;
    tStat(~estimes) = NaN;
    pValeur = 2 * tcdf(-abs(tStat), dfe);

    % --- qualité de l'ajustement ----------------------------------------
    r2 = ssr / sst;
    r2ajuste = 1 - (1 - r2) * (nObs - 1) / dfe;
    logv = -0.5 * nObs * log(2 * pi * mse) + 0.5 * sum(log(w(w > 0))) - 0.5 * sse / mse;
    m = rang;
    criteres = struct('AIC', -2 * logv + 2 * m, ...
                      'AICc', -2 * logv + 2 * m + 2 * m * (m + 1) / (nObs - m - 1), ...
                      'BIC', -2 * logv + m * log(nObs), ...
                      'CAIC', -2 * logv + m * (log(nObs) + 1));

    % --- résidus et diagnostics -----------------------------------------
    levier = zeros(n, 1);
    h = sum(Qr .^ 2, 2);
    levier(sousEnsemble) = h;
    ew = rs .* racine;
    s2i = (sse - ew .^ 2 ./ (1 - h)) / (dfe - 1);
    brut = residus;
    pearson = nan(n, 1);
    pearson(sousEnsemble) = ew / sqrt(mse);
    standardise = nan(n, 1);
    standardise(sousEnsemble) = ew ./ (sqrt(mse) * sqrt(1 - h));
    studentise = nan(n, 1);
    studentise(sousEnsemble) = ew ./ (sqrt(s2i) .* sqrt(1 - h));
    cook = nan(n, 1);
    cook(sousEnsemble) = (ew .^ 2 / (rang * mse)) .* h ./ (1 - h) .^ 2;
    dffits = nan(n, 1);
    dffits(sousEnsemble) = studentise(sousEnsemble) .* sqrt(h ./ (1 - h));
    S2_i = nan(n, 1);
    S2_i(sousEnsemble) = s2i;
    covRatio = nan(n, 1);
    covRatio(sousEnsemble) = (s2i / mse) .^ rang ./ (1 - h);
    dfbetas = zeros(n, k);
    if rang > 0
        inverse = RrInv * RrInv';
        Xp = Xw(:, perm(1:rang));
        dfbeta = (Xp * inverse) .* (ew ./ (1 - h));
        dfbetas(sousEnsemble, perm(1:rang)) = dfbeta ./ sqrt(s2i * diag(inverse).');
    end
    residusT = table(brut, pearson, studentise, standardise, ...
                     'VariableNames', {'Raw', 'Pearson', 'Studentized', 'Standardized'});
    diagnostics = table(levier, cook, dffits, S2_i, covRatio, dfbetas, ...
                        'VariableNames', {'Leverage', 'CooksDistance', 'Dffits', 'S2_i', ...
                                          'CovRatio', 'Dfbetas'});

    % --- le modèle --------------------------------------------------------
    estimation = beta;
    coefficients = table(estimation, se, tStat, pValeur, ...
                         'VariableNames', {'Estimate', 'SE', 'tStat', 'pValue'}, ...
                         'RowNames', nomsCoef);
    infos = table(poids, exclues, manquantes, sousEnsemble, ...
                  'VariableNames', {'Weights', 'Excluded', 'Missing', 'Subset'});
    if ~isempty(e.nomsLignes)
        infos.Properties.RowNames = e.nomsLignes;
        residusT.Properties.RowNames = e.nomsLignes;
        diagnostics.Properties.RowNames = e.nomsLignes;
    end
    champs = struct();
    champs.Coefficients = coefficients;
    champs.CoefficientCovariance = covariance;
    champs.CoefficientNames = nomsCoef(:).';
    champs.NumCoefficients = k;
    champs.NumEstimatedCoefficients = rang;
    champs.DFE = dfe;
    champs.SSE = sse;
    champs.SSR = ssr;
    champs.SST = sst;
    champs.MSE = mse;
    champs.RMSE = sqrt(mse);
    champs.Rsquared = struct('Ordinary', r2, 'Adjusted', r2ajuste);
    champs.LogLikelihood = logv;
    champs.ModelCriterion = criteres;
    champs.Fitted = ajuste;
    champs.Residuals = residusT;
    champs.Diagnostics = diagnostics;
    champs.Formula = classreg.regr.LinearFormula(termes, nomsVariables, iReponse, iPredicteurs);
    champs.NumObservations = nObs;
    champs.NumPredictors = numel(iPredicteurs);
    champs.NumVariables = nVar;
    champs.ObservationInfo = infos;
    champs.ObservationNames = e.nomsLignes;
    champs.PredictorNames = nomsVariables(iPredicteurs);
    champs.PredictorNames = champs.PredictorNames(:).';
    champs.ResponseName = nomsVariables{iReponse};
    champs.VariableNames = nomsVariables(:).';
    champs.Variables = tableDesVariables(e);
    champs.VariableInfo = infosVariables(e, niveaux, iPredicteurs, iReponse);
    champs.Termes = termes;
    champs.EstCategorielle = e.estCat;
    champs.Niveaux = niveaux;
    champs.Estimes = estimes;
    champs.AvecConstante = any(all(termes == 0, 2));
    champs.Beta = beta;
    mdl = LinearModel(champs);
end

% Lecture des arguments de FITLM : données (table ou X, Y), spécification
% du modèle, options.
function e = lireEntrees(args)
    nomsOptions = {'intercept', 'predictorvars', 'responsevar', 'weights', 'exclude', ...
                   'categoricalvars', 'varnames', 'robustopts', 'dummyvarcoding'};
    e = struct();
    if istable(args{1})
        t = args{1};
        e.noms = t.Properties.VariableNames;
        e.noms = e.noms(:).';
        e.donnees = cell(1, numel(e.noms));
        for j = 1:numel(e.noms)
            e.donnees{j} = t.(e.noms{j});
        end
        e.nomsLignes = t.Properties.RowNames;
        e.matrice = false;
        k = 2;
    else
        if numel(args) < 2
            error('stats:fitlm:TooFewInputs', 'FITLM(X,Y) attend X et Y.');
        end
        X = args{1};
        y = args{2};
        if ~(isnumeric(X) || islogical(X)) || ~(isnumeric(y) || islogical(y))
            error('stats:fitlm:BadData', ...
                  'FITLM attend une table, ou une matrice X et un vecteur Y numériques.');
        end
        if isvector(X) && size(X, 1) == 1 && numel(y) == numel(X) && numel(y) > 1
            X = X(:);
        end
        if size(X, 1) ~= numel(y)
            error('stats:fitlm:BadSizes', ...
                  'X a %d lignes et Y %d valeurs : il en faut autant.', size(X, 1), numel(y));
        end
        p = size(X, 2);
        e.noms = [arrayfun(@(j) sprintf('x%d', j), 1:p, 'UniformOutput', false), {'y'}];
        e.donnees = cell(1, p + 1);
        for j = 1:p
            e.donnees{j} = X(:, j);
        end
        e.donnees{p + 1} = y(:);
        e.nomsLignes = {};
        e.matrice = true;
        k = 3;
    end
    e.n = size(e.donnees{1}, 1);
    for j = 1:numel(e.donnees)
        if size(e.donnees{j}, 1) ~= e.n
            error('stats:fitlm:BadSizes', 'Les variables n''ont pas toutes %d lignes.', e.n);
        end
    end

    e.spec = 'linear';
    if k <= numel(args)
        a = args{k};
        estOption = (ischar(a) || (isstring(a) && isscalar(a))) && ...
                    any(strcmpi(char(a), nomsOptions)) && k < numel(args);
        if ~estOption
            e.spec = a;
            k = k + 1;
        end
    end
    reste = args(k:end);
    if mod(numel(reste), 2) ~= 0
        error('stats:fitlm:BadNameValue', ...
              'FITLM : les options vont par paires, un nom et une valeur.');
    end
    e.avecConstante = true;
    e.iPredicteurs = [];
    e.iReponse = [];
    e.poids = ones(e.n, 1);
    e.exclues = false(e.n, 1);
    categorielles = [];
    for j = 1:2:numel(reste)
        nom = lower(char(reste{j}));
        valeur = reste{j + 1};
        switch nom
            case 'intercept'
                e.avecConstante = logical(valeur);
            case 'varnames'
                if ~e.matrice
                    error('stats:fitlm:VarNamesTable', ...
                          ['VarNames ne s''emploie qu''avec une matrice X ; une table ' ...
                           'porte ses noms.']);
                end
                noms = cellstr(valeur);
                if numel(noms) ~= numel(e.noms)
                    error('stats:fitlm:BadVarNames', ...
                          'VarNames compte %d noms : les prédicteurs puis la réponse.', ...
                          numel(e.noms));
                end
                e.noms = noms(:).';
            case 'predictorvars'
                e.iPredicteurs = valeur;
            case 'responsevar'
                e.iReponse = valeur;
            case 'weights'
                w = double(valeur(:));
                if numel(w) ~= e.n || any(w < 0)
                    error('stats:fitlm:BadWeights', ...
                          'Weights compte un poids positif ou nul par observation (%d).', e.n);
                end
                e.poids = w;
            case 'exclude'
                if islogical(valeur)
                    if numel(valeur) ~= e.n
                        error('stats:fitlm:BadExclude', ...
                              'Exclude logique compte une valeur par observation.');
                    end
                    e.exclues = valeur(:);
                else
                    e.exclues(valeur) = true;
                end
            case 'categoricalvars'
                categorielles = valeur;
            case 'robustopts'
                if ~((ischar(valeur) || isstring(valeur)) && strcmpi(char(valeur), 'off')) && ...
                        ~(islogical(valeur) && ~valeur)
                    error('stats:fitlm:NotSupported', ...
                          ['RobustOpts n''est pas pris en charge par FITLM dans MatLibre ; ' ...
                           'ROBUSTFIT ajuste un modèle robuste.']);
                end
            case 'dummyvarcoding'
                if ~strcmpi(char(valeur), 'reference')
                    error('stats:fitlm:NotSupported', ...
                          ['DummyVarCoding n''admet dans MatLibre que ''reference'' : la ' ...
                           'première catégorie sert de référence.']);
                end
            otherwise
                error('stats:fitlm:BadNameValue', 'FITLM n''a pas d''option ''%s''.', ...
                      char(reste{j}));
        end
    end
    e.iPredicteurs = indicesDeVariables(e.iPredicteurs, e.noms, 'PredictorVars');
    e.iReponse = indicesDeVariables(e.iReponse, e.noms, 'ResponseVar');
    if numel(e.iReponse) > 1
        error('stats:fitlm:BadResponseVar', 'ResponseVar désigne une seule variable.');
    end
    nVar = numel(e.noms);
    e.estCat = false(1, nVar);
    for j = 1:nVar
        d = e.donnees{j};
        e.estCat(j) = iscategorical(d) || iscell(d) || isstring(d) || ischar(d) || islogical(d);
    end
    if ~isempty(categorielles)
        e.estCat(indicesDeVariables(categorielles, e.noms, 'CategoricalVars')) = true;
    end
end

function indices = indicesDeVariables(valeur, noms, option)
    if isempty(valeur)
        indices = [];
        return
    end
    if islogical(valeur)
        indices = find(valeur);
    elseif isnumeric(valeur)
        indices = double(valeur(:).');
    else
        cherches = cellstr(valeur);
        indices = zeros(1, numel(cherches));
        for k = 1:numel(cherches)
            i = find(strcmp(noms, cherches{k}), 1);
            if isempty(i)
                error('stats:fitlm:BadVarName', '%s : pas de variable ''%s''.', ...
                      option, cherches{k});
            end
            indices(k) = i;
        end
    end
    if any(indices < 1 | indices > numel(noms) | indices ~= round(indices))
        error('stats:fitlm:BadVarIndex', '%s désigne une variable inexistante.', option);
    end
end

% Les termes du modèle, une ligne par terme et une colonne par variable,
% et le rang de la réponse.
function [termes, iReponse] = termesDuModele(e)
    nVar = numel(e.noms);
    spec = e.spec;
    if isstring(spec) && isscalar(spec)
        spec = char(spec);
    end
    if ischar(spec) && contains(spec, '~')
        [termes, iReponse] = lireFormule(spec, e.noms);
        return
    end
    if isempty(e.iReponse)
        if isempty(e.iPredicteurs)
            iReponse = nVar;
        else
            restants = setdiff(1:nVar, e.iPredicteurs);
            iReponse = restants(end);
        end
    else
        iReponse = e.iReponse;
    end
    if isnumeric(spec)
        termes = double(spec);
        if size(termes, 2) ~= nVar
            if size(termes, 2) == nVar - 1
                % Sans la colonne de la réponse : on l'ajoute, nulle.
                complet = zeros(size(termes, 1), nVar);
                complet(:, setdiff(1:nVar, iReponse)) = termes;
                termes = complet;
            else
                error('stats:fitlm:BadTerms', ...
                      'La matrice des termes compte une colonne par variable (%d).', nVar);
            end
        end
        if any(termes(:) < 0 | termes(:) ~= round(termes(:)))
            error('stats:fitlm:BadTerms', ...
                  'La matrice des termes porte des puissances entières positives.');
        end
        return
    end
    if ~ischar(spec)
        error('stats:fitlm:BadModelSpec', ...
              'La spécification du modèle est un nom, une formule ou une matrice de termes.');
    end
    if isempty(e.iPredicteurs)
        iPredicteurs = setdiff(1:nVar, iReponse);
    else
        iPredicteurs = setdiff(e.iPredicteurs, iReponse);
    end
    p = numel(iPredicteurs);
    I = zeros(p, nVar);
    for j = 1:p
        I(j, iPredicteurs(j)) = 1;
    end
    continus = ~e.estCat(iPredicteurs);
    constante = zeros(1, nVar);
    paires = zeros(0, nVar);
    for a = 1:p
        for b = a + 1:p
            paires(end + 1, :) = I(a, :) + I(b, :); %#ok<AGROW>
        end
    end
    carres = 2 * I(continus, :);
    switch lower(spec)
        case 'constant'
            termes = constante;
        case 'linear'
            termes = [constante; I];
        case 'interactions'
            termes = [constante; I; paires];
        case 'purequadratic'
            termes = [constante; I; carres];
        case 'quadratic'
            termes = [constante; I; paires; carres];
        otherwise
            if strncmpi(spec, 'poly', 4) && numel(spec) > 4 && all(isstrprop(spec(5:end), 'digit'))
                degres = spec(5:end) - '0';
                if numel(degres) ~= p
                    error('stats:fitlm:BadPoly', ...
                          '%s donne %d degrés pour %d prédicteurs.', spec, numel(degres), p);
                end
                if any(degres(~continus) > 1)
                    error('stats:fitlm:BadPoly', ...
                          'Un prédicteur catégoriel ne peut dépasser le degré un.');
                end
                termes = polynome(degres, iPredicteurs, nVar);
            else
                error('stats:fitlm:BadModelSpec', ...
                      ['Modèle inconnu : ''%s''. Noms admis : constant, linear, interactions, ' ...
                       'purequadratic, quadratic, polyIJK, ou une formule « y ~ ... ».'], spec);
            end
    end
end

% 'polyIJK' : tous les termes dont chaque puissance reste sous le degré de
% sa variable et dont le degré total ne dépasse pas le plus grand.
function termes = polynome(degres, iPredicteurs, nVar)
    p = numel(degres);
    total = max(degres);
    nb = prod(degres + 1);
    termes = zeros(0, nVar);
    for code = 0:nb - 1
        reste = code;
        e = zeros(1, p);
        for j = 1:p
            e(j) = mod(reste, degres(j) + 1);
            reste = floor(reste / (degres(j) + 1));
        end
        if sum(e) <= total
            ligne = zeros(1, nVar);
            ligne(iPredicteurs) = e;
            termes(end + 1, :) = ligne; %#ok<AGROW>
        end
    end
end

% L'ordre de MATLAB : par degré, puis les interactions avant les
% puissances (plus grande puissance croissante), puis dans l'ordre des
% variables.
function termes = trierTermes(termes)
    termes = unique(termes, 'rows');
    cle = [sum(termes, 2), max([termes, zeros(size(termes, 1), 1)], [], 2), -termes];
    [~, ordre] = sortrows(cle);
    termes = termes(ordre, :);
end

% ----------------------------------------------------------------------
% Formules de Wilkinson : « y ~ x1 + x2 », « y ~ x1*x2 - x1:x2 »,
% « y ~ x1^2 + x2 », « y ~ x1 - 1 ».
% ----------------------------------------------------------------------
function [termes, iReponse] = lireFormule(texte, noms)
    morceaux = strsplit(texte, '~');
    if numel(morceaux) ~= 2
        error('stats:fitlm:BadFormula', 'Une formule a la forme « reponse ~ termes ».');
    end
    reponse = strtrim(morceaux{1});
    iReponse = find(strcmp(noms, reponse), 1);
    if isempty(iReponse)
        error('stats:fitlm:BadFormula', 'La réponse ''%s'' n''est pas une variable.', reponse);
    end
    jetons = jetonsDe(morceaux{2});
    position = 1;
    nVar = numel(noms);
    [ensemble, position, constante] = lireSomme(jetons, position, noms, nVar);
    if position <= numel(jetons)
        error('stats:fitlm:BadFormula', 'Formule mal formée près de ''%s''.', jetons{position});
    end
    termes = ensemble;
    if constante
        termes = [zeros(1, nVar); termes];
    end
    termes = unique(termes, 'rows');
end

function jetons = jetonsDe(texte)
    jetons = {};
    i = 1;
    n = numel(texte);
    while i <= n
        c = texte(i);
        if isspace(c)
            i = i + 1;
        elseif any(c == '+-*:^()')
            jetons{end + 1} = c; %#ok<AGROW>
            i = i + 1;
        elseif isletter(c) || c == '_' || isstrprop(c, 'digit')
            j = i;
            while j <= n && (isletter(texte(j)) || texte(j) == '_' || isstrprop(texte(j), 'digit'))
                j = j + 1;
            end
            jetons{end + 1} = texte(i:j - 1); %#ok<AGROW>
            i = j;
        else
            error('stats:fitlm:BadFormula', 'Caractère inattendu dans la formule : ''%s''.', c);
        end
    end
end

% somme := ['-'] produit { ('+'|'-') produit } ; la constante est là par
% défaut, « - 1 » ou « 0 » la retire.
function [ensemble, position, constante] = lireSomme(jetons, position, noms, nVar)
    ensemble = zeros(0, nVar);
    constante = true;
    signe = 1;
    if position <= numel(jetons) && strcmp(jetons{position}, '-')
        signe = -1;
        position = position + 1;
    end
    while true
        if position > numel(jetons)
            error('stats:fitlm:BadFormula', 'Formule incomplète.');
        end
        if any(strcmp(jetons{position}, {'1', '0'}))
            valeur = jetons{position};
            position = position + 1;
            if strcmp(valeur, '0') || signe < 0
                constante = false;
            else
                constante = true;
            end
        else
            [morceau, position] = lireProduit(jetons, position, noms, nVar);
            if signe > 0
                ensemble = union(ensemble, morceau, 'rows');
            else
                ensemble = setdiff(ensemble, morceau, 'rows');
                if any(all(morceau == 0, 2))
                    constante = false;
                end
            end
        end
        if position > numel(jetons) || strcmp(jetons{position}, ')')
            break
        end
        if strcmp(jetons{position}, '+')
            signe = 1;
        elseif strcmp(jetons{position}, '-')
            signe = -1;
        else
            error('stats:fitlm:BadFormula', 'Formule mal formée près de ''%s''.', ...
                  jetons{position});
        end
        position = position + 1;
    end
    ensemble = ensemble(any(ensemble > 0, 2), :);
end

% produit := interaction { '*' interaction } : A*B = A + B + A:B.
function [ensemble, position] = lireProduit(jetons, position, noms, nVar)
    [ensemble, position] = lireInteraction(jetons, position, noms, nVar);
    while position <= numel(jetons) && strcmp(jetons{position}, '*')
        [autre, position] = lireInteraction(jetons, position + 1, noms, nVar);
        ensemble = union(union(ensemble, autre, 'rows'), croiser(ensemble, autre), 'rows');
    end
end

% interaction := puissance { ':' puissance }.
function [ensemble, position] = lireInteraction(jetons, position, noms, nVar)
    [ensemble, position] = lirePuissance(jetons, position, noms, nVar);
    while position <= numel(jetons) && strcmp(jetons{position}, ':')
        [autre, position] = lirePuissance(jetons, position + 1, noms, nVar);
        ensemble = croiser(ensemble, autre);
    end
end

% puissance := primaire [ '^' entier ] ; A^k = A + A^2 + ... + A^k.
function [ensemble, position] = lirePuissance(jetons, position, noms, nVar)
    if position > numel(jetons)
        error('stats:fitlm:BadFormula', 'Formule incomplète.');
    end
    jeton = jetons{position};
    if strcmp(jeton, '(')
        [ensemble, position, ~] = lireSomme(jetons, position + 1, noms, nVar);
        if position > numel(jetons) || ~strcmp(jetons{position}, ')')
            error('stats:fitlm:BadFormula', 'Parenthèse non fermée dans la formule.');
        end
        position = position + 1;
        entreParentheses = true;
    else
        i = find(strcmp(noms, jeton), 1);
        if isempty(i)
            error('stats:fitlm:BadFormula', ...
                  'La formule nomme ''%s'', qui n''est pas une variable.', jeton);
        end
        ensemble = zeros(1, nVar);
        ensemble(i) = 1;
        position = position + 1;
        entreParentheses = false;
    end
    if position <= numel(jetons) && strcmp(jetons{position}, '^')
        if position + 1 > numel(jetons) || isempty(str2double(jetons{position + 1})) || ...
                isnan(str2double(jetons{position + 1}))
            error('stats:fitlm:BadFormula', 'Une puissance est un entier positif.');
        end
        k = str2double(jetons{position + 1});
        position = position + 2;
        if entreParentheses || size(ensemble, 1) ~= 1
            error('stats:fitlm:NotSupported', ...
                  ['Une puissance d''une somme, « (A + B)^k », n''est pas prise en charge ' ...
                   'par MatLibre : écrivez les termes.']);
        end
        base = ensemble;
        ensemble = zeros(k, nVar);
        for p = 1:k
            ensemble(p, :) = p * base;
        end
    end
end

function r = croiser(a, b)
    r = zeros(size(a, 1) * size(b, 1), size(a, 2));
    i = 0;
    for x = 1:size(a, 1)
        for y = 1:size(b, 1)
            i = i + 1;
            r(i, :) = a(x, :) + b(y, :);
        end
    end
    r = unique(r, 'rows');
end

% ----------------------------------------------------------------------
% Matrice de conception
% ----------------------------------------------------------------------

% Les niveaux d'une variable catégorielle et le rang de chaque ligne parmi
% eux (NaN : manquant, ou niveau inconnu du modèle).
function [niveaux, rangs, manquant] = niveauxDe(colonne, connus, garder)
    if iscategorical(colonne)
        texte = cellstr(colonne(:));
        manquant = isundefined(colonne(:));
        ordre = categories(colonne);
    elseif islogical(colonne)
        valeurs = double(colonne(:));
        texte = arrayfun(@(v) sprintf('%d', v), valeurs, 'UniformOutput', false);
        manquant = false(size(valeurs));
        ordre = {'0'; '1'};
    elseif iscell(colonne)
        texte = colonne(:);
        manquant = cellfun(@(c) isempty(c) || (isstring(c) && ismissing(c)), texte);
        texte(manquant) = {''};
        texte = cellfun(@char, texte, 'UniformOutput', false);
        ordre = unique(texte(~manquant));
    elseif isstring(colonne)
        manquant = ismissing(colonne(:)) | colonne(:) == "";
        texte = cellstr(colonne(:));
        ordre = unique(texte(~manquant));
    elseif ischar(colonne)
        texte = cellstr(colonne);
        manquant = cellfun(@isempty, strtrim(texte));
        ordre = unique(texte(~manquant));
    else
        valeurs = double(colonne(:));
        manquant = isnan(valeurs);
        distincts = unique(valeurs(~manquant));
        texte = cell(size(valeurs));
        texte(~manquant) = arrayfun(@num2str, valeurs(~manquant), 'UniformOutput', false);
        texte(manquant) = {''};
        ordre = arrayfun(@num2str, distincts, 'UniformOutput', false);
    end
    if ~isempty(connus)
        niveaux = connus;
    else
        if nargin < 3
            garder = ~manquant;
        end
        presents = unique(texte(garder & ~manquant));
        niveaux = ordre(ismember(ordre, presents));
        niveaux = niveaux(:);
    end
    [trouve, rangs] = ismember(texte, niveaux);
    rangs = double(rangs);
    rangs(~trouve | manquant) = NaN;
end

% Les colonnes de la matrice de conception et leurs noms. Une variable
% continue entre élevée à sa puissance ; une catégorielle par ses
% indicatrices, la première catégorie servant de référence ; un terme
% multiplie les colonnes de ses variables.
function [D, noms] = conception(termes, donnees, estCat, niveaux, rangs, nomsVariables)
    n = size(donnees{1}, 1);
    D = zeros(n, 0);
    noms = {};
    for t = 1:size(termes, 1)
        bloc = ones(n, 1);
        nomsBloc = {''};
        for v = find(termes(t, :) > 0)
            e = termes(t, v);
            if estCat(v)
                L = numel(niveaux{v});
                Z = zeros(n, max(L - 1, 0));
                for l = 2:L
                    Z(:, l - 1) = double(rangs{v} == l);
                end
                Z(isnan(rangs{v}), :) = NaN;
                nomsZ = cellfun(@(nv) [nomsVariables{v} '_' nv], niveaux{v}(2:end), ...
                                'UniformOutput', false);
                nomsZ = nomsZ(:).';
            else
                Z = double(donnees{v});
                Z = Z(:) .^ e;
                if e == 1
                    nomsZ = {nomsVariables{v}};
                else
                    nomsZ = {sprintf('%s^%d', nomsVariables{v}, e)};
                end
            end
            nouveau = zeros(n, size(bloc, 2) * size(Z, 2));
            nouveauxNoms = cell(1, size(bloc, 2) * size(Z, 2));
            c = 0;
            for a = 1:size(bloc, 2)
                for b = 1:size(Z, 2)
                    c = c + 1;
                    nouveau(:, c) = bloc(:, a) .* Z(:, b);
                    if isempty(nomsBloc{a})
                        nouveauxNoms{c} = nomsZ{b};
                    else
                        nouveauxNoms{c} = [nomsBloc{a} ':' nomsZ{b}];
                    end
                end
            end
            bloc = nouveau;
            nomsBloc = nouveauxNoms;
        end
        if all(termes(t, :) == 0)
            nomsBloc = {'(Intercept)'};
        end
        D = [D, bloc]; %#ok<AGROW>
        noms = [noms, nomsBloc]; %#ok<AGROW>
    end
    noms = noms(:);
end

% La matrice de conception de nouvelles données, pour PREDICT.
function D = conceptionNouvelle(mdl, Xnouveau)
    nomsVariables = mdl.VariableNames;
    nVar = numel(nomsVariables);
    iPred = find(ismember(nomsVariables, mdl.PredictorNames));
    if istable(Xnouveau)
        n = height(Xnouveau);
        donnees = cell(1, nVar);
        nomsT = Xnouveau.Properties.VariableNames;
        for v = 1:nVar
            if ismember(v, iPred)
                if ~any(strcmp(nomsT, nomsVariables{v}))
                    error('stats:LinearModel:predict:MissingVar', ...
                          'La table ne porte pas le prédicteur %s.', nomsVariables{v});
                end
                donnees{v} = Xnouveau.(nomsVariables{v});
            else
                donnees{v} = nan(n, 1);
            end
        end
    else
        if isvector(Xnouveau) && numel(iPred) > 1 && size(Xnouveau, 1) == 1
            Xnouveau = Xnouveau(:).';
        elseif isvector(Xnouveau) && numel(iPred) == 1
            Xnouveau = Xnouveau(:);
        end
        if size(Xnouveau, 2) ~= numel(iPred)
            error('stats:LinearModel:predict:BadX', ...
                  'XNEW compte une colonne par prédicteur (%d).', numel(iPred));
        end
        n = size(Xnouveau, 1);
        donnees = cell(1, nVar);
        for v = 1:nVar
            donnees{v} = nan(n, 1);
        end
        for j = 1:numel(iPred)
            donnees{iPred(j)} = Xnouveau(:, j);
        end
    end
    rangs = cell(1, nVar);
    for v = find(mdl.EstCategorielle & any(mdl.Termes > 0, 1))
        [~, rangs{v}] = niveauxDe(donnees{v}, mdl.Niveaux{v});
    end
    D = conception(mdl.Termes, donnees, mdl.EstCategorielle, mdl.Niveaux, rangs, nomsVariables);
end

function t = tableDesVariables(e)
    t = table(e.donnees{:}, 'VariableNames', e.noms);
    if ~isempty(e.nomsLignes)
        t.Properties.RowNames = e.nomsLignes;
    end
end

function t = infosVariables(e, niveaux, iPredicteurs, iReponse)
    nVar = numel(e.noms);
    classes = cell(nVar, 1);
    etendues = cell(nVar, 1);
    dansModele = false(nVar, 1);
    dansModele(iPredicteurs) = true;
    for v = 1:nVar
        d = e.donnees{v};
        classes{v} = class(d);
        if e.estCat(v)
            if isempty(niveaux{v})
                etendues{v} = niveauxDe(d, {});
            else
                etendues{v} = niveaux{v};
            end
        else
            d = double(d);
            etendues{v} = [min(d), max(d)];
        end
    end
    estCategorielle = e.estCat(:);
    t = table(classes, etendues, dansModele, estCategorielle, ...
              'VariableNames', {'Class', 'Range', 'InModel', 'IsCategorical'}, ...
              'RowNames', e.noms(:));
    t.InModel(iReponse) = false;
end

% ANOVA par terme. 'h' : un terme est jugé dans le modèle privé des termes
% qui le contiennent ; 1 : séquentiel ; 3 : après tous les autres.
function tbl = anovaComposantes(mdl, typeSomme)
    if isnumeric(typeSomme)
        typeSomme = sprintf('%d', typeSomme);
    end
    typeSomme = lower(char(typeSomme));
    if ~any(strcmp(typeSomme, {'1', '3', 'h'}))
        error('stats:LinearModel:anova:BadSSType', ...
              ['MatLibre calcule les sommes de carrés de types 1, 3 et ''h'' ; ' ...
               'le type ''%s'' n''est pas pris en charge.'], typeSomme);
    end
    termes = mdl.Termes;
    nomsVariables = mdl.VariableNames;
    donnees = cell(1, numel(nomsVariables));
    for v = 1:numel(nomsVariables)
        donnees{v} = mdl.Variables.(nomsVariables{v});
    end
    rangs = cell(1, numel(nomsVariables));
    for v = find(mdl.EstCategorielle & any(termes > 0, 1))
        [~, rangs{v}] = niveauxDe(donnees{v}, mdl.Niveaux{v});
    end
    sous = mdl.ObservationInfo.Subset;
    w = mdl.ObservationInfo.Weights(sous);
    y = double(donnees{strcmp(nomsVariables, mdl.ResponseName)});
    y = y(sous);
    % Les colonnes de chaque terme.
    colonnesDe = cell(size(termes, 1), 1);
    Dtout = zeros(sum(sous), 0);
    for t = 1:size(termes, 1)
        Dt = conception(termes(t, :), donnees, mdl.EstCategorielle, mdl.Niveaux, rangs, ...
                        nomsVariables);
        colonnesDe{t} = size(Dtout, 2) + (1:size(Dt, 2));
        Dtout = [Dtout, Dt(sous, :)]; %#ok<AGROW>
    end
    autres = find(any(termes > 0, 2));
    nomsTermes = mdl.Formula.TermNames(autres);
    nT = numel(autres);
    sommes = zeros(nT, 1);
    ddl = zeros(nT, 1);
    tousIndices = 1:size(termes, 1);
    sseComplet = sseSur(Dtout(:, [colonnesDe{tousIndices}]), y, w);
    for i = 1:nT
        t = autres(i);
        switch typeSomme
            case '3'
                base = tousIndices;
            case 'h'
                contenant = false(size(termes, 1), 1);
                for u = 1:size(termes, 1)
                    contenant(u) = u ~= t && all(termes(u, :) >= termes(t, :)) && ...
                                   any(termes(u, :) > termes(t, :));
                end
                base = tousIndices(~contenant);
            case '1'
                base = tousIndices(1:t);
        end
        [sseAvec, rangAvec] = sseSur(Dtout(:, [colonnesDe{base}]), y, w);
        sans = base(base ~= t);
        [sseSans, rangSans] = sseSur(Dtout(:, [colonnesDe{sans}]), y, w);
        sommes(i) = sseSans - sseAvec;
        ddl(i) = rangAvec - rangSans;
    end
    moyennes = sommes ./ ddl;
    F = moyennes / mdl.MSE;
    p = fcdf(F, ddl, mdl.DFE, 'upper');
    sommes = [sommes; sseComplet];
    ddl = [ddl; mdl.DFE];
    moyennes = [moyennes; mdl.MSE];
    F = [F; NaN];
    p = [p; NaN];
    tbl = table(sommes, ddl, moyennes, F, p, ...
                'VariableNames', {'SumSq', 'DF', 'MeanSq', 'F', 'pValue'}, ...
                'RowNames', [nomsTermes(:); {'Error'}]);
end

function [sse, rang] = sseSur(D, y, w)
    racine = sqrt(w);
    Xw = D .* racine;
    yw = y .* racine;
    if isempty(Xw)
        sse = sum(yw .^ 2);
        rang = 0;
        return
    end
    [Q, R, ~] = qr(Xw, 0);
    diagonale = abs(diag(R));
    rang = sum(diagonale > max(size(Xw)) * eps(diagonale(1)));
    Qr = Q(:, 1:rang);
    sse = sum((yw - Qr * (Qr' * yw)) .^ 2);
end
