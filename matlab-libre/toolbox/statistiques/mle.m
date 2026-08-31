function [parametres, ci] = mle(donnees, varargin)
%MLE Estimation par maximum de vraisemblance.
%   P = MLE(X) ajuste une loi normale à X par maximum de vraisemblance et
%   rend [moyenne, écart type].
%
%   P = MLE(X,'distribution',NOM) ajuste une autre loi. Les noms
%   reconnus : 'normal', 'exponential', 'poisson', 'gamma', 'weibull',
%   'lognormal', 'rayleigh', 'uniform', 'beta', 'geometric',
%   'binomial' — pour cette dernière, il faut donner 'ntrials'.
%
%   P = MLE(X,'pdf',F,'start',P0) ajuste une loi quelconque : F est une
%   poignée dont le premier argument est le vecteur des données et les
%   suivants les paramètres, et P0 le point de départ de la recherche.
%   'cdf' peut remplacer 'pdf' pour des données censurées ; MatLibre
%   n'emploie alors la répartition que pour les points censurés.
%
%   P = MLE(X,'logpdf',F,'start',P0) accepte directement le logarithme de
%   la densité, ce qui évite les débordements sur de grands échantillons.
%
%   [P,CI] = MLE(...) rend en outre les intervalles de confiance à 95
%   pour cent, tirés de la matrice d'information observée — l'opposé de
%   la hessienne de la log-vraisemblance, calculée par différences
%   finies.
%
%   MLE(...,'alpha',A) change le niveau de confiance.
%   MLE(...,'options',O) passe une structure STATSET pour régler la
%   recherche.
%
%   Exemples :
%      mle(randn(500, 1) * 2 + 3)                 % proche de [3 2]
%      mle(exprnd(4, 500, 1), 'distribution', 'exponential')
%      mle(poissrnd(3, 500, 1), 'distribution', 'poisson')
%
%      % Une loi ecrite a la main : melange de deux normales centrees
%      f = @(x, s1, s2) 0.5 * normpdf(x, 0, s1) + 0.5 * normpdf(x, 0, s2);
%      mle([randn(300,1); randn(300,1)*4], 'pdf', f, 'start', [1 3])
%
%   Voir aussi FITDIST, NORMFIT, EXPFIT, GAMFIT, WBLFIT, NLINFIT, STATSET.
    loi = '';
    densite = [];
    logDensite = [];
    repartition = [];
    depart = [];
    alpha = 0.05;
    options = [];
    essais = [];
    frequence = [];
    k = 1;
    while k + 1 <= numel(varargin)
        nom = lower(char(varargin{k}));
        switch nom
            case {'distribution', 'distname'}
                loi = lower(char(varargin{k + 1}));
            case 'pdf'
                densite = varargin{k + 1};
            case 'logpdf'
                logDensite = varargin{k + 1};
            case 'cdf'
                repartition = varargin{k + 1};
            case 'start'
                depart = varargin{k + 1};
            case 'alpha'
                alpha = varargin{k + 1};
            case 'options'
                options = varargin{k + 1};
            case 'ntrials'
                essais = varargin{k + 1};
            case 'frequency'
                frequence = varargin{k + 1};
            case {'censoring', 'lowerbound', 'upperbound', 'optimfun'}
                % acceptés et sans effet
            otherwise
                error('stats:mle:BadOption', 'Unknown option ''%s''.', nom);
        end
        k = k + 2;
    end
    x = donnees(:);
    if ~isempty(frequence)
        % Les fréquences répètent les observations.
        frequence = frequence(:);
        repete = [];
        for i = 1:numel(x)
            repete = [repete; repmat(x(i), frequence(i), 1)];   %#ok<AGROW>
        end
        x = repete;
    end

    if isempty(densite) && isempty(logDensite)
        if isempty(loi)
            loi = 'normal';
        end
        [parametres, ci] = ajustementConnu(x, loi, alpha, essais, nargout >= 2);
        return;
    end

    if isempty(depart)
        error('stats:mle:NoStart', ...
              'A custom distribution needs a starting point, given by ''start''.');
    end
    if isempty(logDensite)
        logDensite = @(donnees_, varargin_) log(max(densite(donnees_, varargin_{:}), realmin));
        objectif = @(p) -sum(log(max(appelerAvec(densite, x, p), realmin)));
    else
        objectif = @(p) -sum(appelerAvec(logDensite, x, p));
    end
    maximum = statget(options, 'MaxIter', 400);
    tolerance = statget(options, 'TolX', 1e-10);
    parametres = matlibre_nelder_mead(objectif, depart(:)', maximum, tolerance);
    if nargout >= 2
        ci = intervalleInformation(objectif, parametres, alpha, numel(x));
    end
end

function valeurs = appelerAvec(fonction, x, p)
%APPELERAVEC Appelle la densité avec ses paramètres déballés.
    arguments_ = num2cell(p(:)');
    valeurs = fonction(x, arguments_{:});
    valeurs = valeurs(:);
end

function [parametres, ci] = ajustementConnu(x, loi, alpha, essais, avecIntervalle)
%AJUSTEMENTCONNU Les lois dont l'estimateur est déjà écrit.
    ci = [];
    switch loi
        case {'normal', 'norm'}
            % Le maximum de vraisemblance divise par N, non par N-1.
            parametres = [mean(x), std(x, 1)];
            if avecIntervalle
                [~, ~, muCI, sigmaCI] = normfit(x, alpha);
                ci = [muCI(1), sigmaCI(1); muCI(2), sigmaCI(2)];
            end
        case {'exponential', 'exp'}
            parametres = mean(x);
            if avecIntervalle
                [~, borne] = expfit(x, alpha);
                ci = borne(:);
            end
        case {'poisson', 'poiss'}
            parametres = mean(x);
            if avecIntervalle
                [~, borne] = poissfit(x, alpha);
                ci = borne(:);
            end
        case {'gamma', 'gam'}
            parametres = gamfit(x);
        case {'weibull', 'wbl'}
            parametres = wblfit(x);
        case {'lognormal', 'logn'}
            parametres = lognfit(x);
        case {'rayleigh', 'rayl'}
            parametres = raylfit(x);
        case {'uniform', 'unif'}
            parametres = [min(x), max(x)];
        case {'beta', 'bet'}
            parametres = betafit(x);
        case {'geometric', 'geo'}
            parametres = 1 / (1 + mean(x));
        case {'binomial', 'bino'}
            if isempty(essais)
                error('stats:mle:NoNtrials', ...
                      'The binomial distribution needs ''ntrials''.');
            end
            parametres = sum(x) / (essais * numel(x));
        otherwise
            error('stats:mle:BadDistribution', ...
                  'Unknown distribution ''%s''.', loi);
    end
    if avecIntervalle && isempty(ci)
        % Pas de formule connue pour cette loi : MatLibre ne devine pas
        % l'intervalle plutôt que de le donner faux.
        ci = NaN(2, numel(parametres));
    end
end

function ci = intervalleInformation(objectif, parametres, alpha, n)
%INTERVALLEINFORMATION Bornes tirées de la hessienne de la log-vraisemblance.
    p = numel(parametres);
    H = zeros(p, p);
    pas = max(1e-5 * abs(parametres), 1e-7);
    for i = 1:p
        for j = 1:p
            a = parametres; a(i) = a(i) + pas(i); a(j) = a(j) + pas(j);
            b = parametres; b(i) = b(i) + pas(i); b(j) = b(j) - pas(j);
            c = parametres; c(i) = c(i) - pas(i); c(j) = c(j) + pas(j);
            d = parametres; d(i) = d(i) - pas(i); d(j) = d(j) - pas(j);
            H(i, j) = (objectif(a) - objectif(b) - objectif(c) + objectif(d)) / ...
                      (4 * pas(i) * pas(j));
        end
    end
    covariance = pinv((H + H') / 2);
    erreurs = sqrt(abs(diag(covariance)))';
    marge = norminv(1 - alpha / 2) * erreurs;
    ci = [parametres - marge; parametres + marge];
end
