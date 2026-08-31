function loi = fitdist(x, nom, varargin)
%FITDIST Ajuste une loi de probabilité à des données.
%   PD = FITDIST(X,NOM) ajuste à X la loi nommée et rend un objet qui la
%   décrit. NOM est l'un de 'Normal', 'Exponential', 'Poisson', 'Gamma',
%   'Weibull', 'Lognormal', 'Rayleigh', 'Uniform', 'Beta', 'Binomial',
%   'Kernel', 'Extreme Value'.
%
%   L'objet rendu porte les champs :
%      DistributionName  le nom de la loi ;
%      ParameterNames    le nom de chaque paramètre ;
%      ParameterValues   leurs valeurs estimées ;
%      NumParameters     leur nombre ;
%      InputData         les données ajustées.
%
%   et, pour les lois qui en ont, un champ par paramètre : mu, sigma, a,
%   b, lambda, selon la loi.
%
%   Les fonctions PDF, CDF, ICDF et RANDOM acceptent cet objet en
%   premier argument :
%
%      pd = fitdist(x, 'Normal');
%      pdf(pd, 0)                % la densite en zero
%      icdf(pd, 0.95)            % le quantile a 95 %
%      random(pd, 100, 1)        % cent tirages
%
%   PD = FITDIST(X,NOM,'By',GROUPE) ajuste une loi par groupe et rend un
%   tableau de cellules d'objets.
%
%   Exemples :
%      pd = fitdist(normrnd(5, 2, 500, 1), 'Normal');
%      [pd.mu, pd.sigma]                    % proche de [5 2]
%      pdf(pd, 5)
%
%      pd = fitdist(exprnd(3, 500, 1), 'Exponential');
%      pd.mu
%
%   Voir aussi MLE, NORMFIT, PDF, CDF, ICDF, RANDOM, HISTFIT, PROBPLOT.
    groupe = [];
    k = 1;
    while k + 1 <= numel(varargin)
        option = lower(char(varargin{k}));
        if strcmp(option, 'by')
            groupe = varargin{k + 1};
        elseif any(strcmp(option, {'censoring', 'frequency', 'options', 'ntrials', ...
                                   'width', 'kernel', 'support'}))
            % acceptés et sans effet
        else
            error('stats:fitdist:BadOption', 'Unknown option ''%s''.', option);
        end
        k = k + 2;
    end
    if ~isempty(groupe)
        [indices, noms] = grp2idx(groupe);
        loi = cell(numel(noms), 1);
        for g = 1:numel(noms)
            loi{g} = fitdist(x(indices == g), nom);
        end
        return;
    end

    x = double(x(:));
    x = x(~isnan(x));
    court = lower(char(nom));
    switch court
        case {'normal', 'norm'}
            [mu, sigma] = normfit(x);
            loi = objet('Normal', {'mu', 'sigma'}, [mu, sigma], x);
        case {'exponential', 'exp'}
            loi = objet('Exponential', {'mu'}, expfit(x), x);
        case {'poisson', 'poiss'}
            loi = objet('Poisson', {'lambda'}, poissfit(x), x);
        case {'gamma', 'gam'}
            parametres = gamfit(x);
            loi = objet('Gamma', {'a', 'b'}, parametres, x);
        case {'weibull', 'wbl'}
            parametres = wblfit(x);
            loi = objet('Weibull', {'A', 'B'}, parametres, x);
        case {'lognormal', 'logn'}
            parametres = lognfit(x);
            loi = objet('Lognormal', {'mu', 'sigma'}, parametres, x);
        case {'rayleigh', 'rayl'}
            loi = objet('Rayleigh', {'B'}, raylfit(x), x);
        case {'uniform', 'unif'}
            loi = objet('Uniform', {'Lower', 'Upper'}, [min(x), max(x)], x);
        case {'beta', 'bet'}
            loi = objet('Beta', {'a', 'b'}, betafit(x), x);
        case {'extreme value', 'ev'}
            sigma = std(x) * sqrt(6) / pi;
            if sigma <= 0
                sigma = 1;
            end
            mu = mean(x) + 0.5772156649015329 * sigma;
            loi = objet('Extreme Value', {'mu', 'sigma'}, [mu, sigma], x);
        case {'kernel', 'ks'}
            loi = objet('Kernel', {}, [], x);
        otherwise
            error('stats:fitdist:BadDistribution', ...
                  'Unknown distribution ''%s''.', char(nom));
    end
end

function loi = objet(nomLoi, nomsParametres, valeurs, donnees)
%OBJET La structure que FITDIST rend, uniforme d'une loi à l'autre.
    loi = struct('DistributionName', nomLoi, ...
                 'ParameterNames', {nomsParametres}, ...
                 'ParameterValues', valeurs, ...
                 'NumParameters', numel(valeurs), ...
                 'InputData', donnees);
    for i = 1:numel(nomsParametres)
        loi.(nomsParametres{i}) = valeurs(i);
    end
end
