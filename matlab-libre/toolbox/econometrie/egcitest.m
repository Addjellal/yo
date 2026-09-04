function [rejet, pValeur, statistique, valeurCritique, regression, residuelle] = egcitest(Y, varargin)
%EGCITEST Test de cointégration d'Engle et Granger.
%   H = EGCITEST(Y) teste si les colonnes de Y sont cointégrées. H vaut
%   un quand l'absence de cointégration est rejetée : une combinaison
%   linéaire des séries est stationnaire, alors que chacune prise seule
%   ne l'est pas.
%
%   La méthode tient en deux temps. On régresse d'abord la première
%   colonne sur les autres : si les séries sont cointégrées, les résidus
%   de cette régression sont stationnaires. On leur applique ensuite un
%   test de racine unitaire. Comme la relation a été estimée et non
%   donnée, les valeurs critiques sont plus sévères que celles du test de
%   racine unitaire ordinaire, et d'autant plus que les régresseurs sont
%   nombreux.
%
%   EGCITEST(...,'creg',C) choisit les termes déterministes de la
%   régression de cointégration — 'nc' aucun, 'c' une constante
%   (défaut), 'ct' constante et tendance. 'rreg',R choisit le test des
%   résidus — 'adf' (défaut) ou 'pp'. 'lags',L le nombre de retards,
%   'test',T la forme — 't1', le rapport de Student (défaut), ou 't2',
%   le coefficient normalisé —, 'alpha',A le seuil (0,05).
%   'cvec',B impose le vecteur de cointégration au lieu de l'estimer :
%   les valeurs critiques deviennent alors celles d'un simple test de
%   racine unitaire.
%
%   [H,P,STAT,CRIT,REG1,REG2] = EGCITEST(...) rend en plus la régression
%   de cointégration et la régression sur les résidus.
%
%   Exemple :
%      x = cumsum(randn(300, 1));
%      y = 2 * x + randn(300, 1);      % cointegrees
%      egcitest([y, x])                % 1
%      egcitest([cumsum(randn(300, 1)), cumsum(randn(300, 1))])  % 0
%
%   Voir aussi JCITEST, ADFTEST, PPTEST, LMCTEST.
    Y = double(Y);
    if size(Y, 1) < size(Y, 2)
        Y = Y.';
    end
    [T, n] = size(Y);
    if n < 2
        error('econ:egcitest:Series', ...
              'Il faut au moins deux séries pour parler de cointégration.');
    end
    creg = 'c';
    rreg = 'adf';
    retards = 0;
    forme = 't1';
    alpha = 0.05;
    vecteur = [];
    k = 1;
    while k + 1 <= numel(varargin)
        switch lower(char(varargin{k}))
            case 'creg',  creg = lower(char(varargin{k+1}));
            case 'rreg',  rreg = lower(char(varargin{k+1}));
            case 'lags',  retards = round(varargin{k+1});
            case 'test',  forme = lower(char(varargin{k+1}));
            case 'alpha', alpha = varargin{k+1};
            case 'cvec',  vecteur = varargin{k+1}(:);
            otherwise
                error('econ:egcitest:Option', ...
                      'Option inconnue : %s.', char(varargin{k}));
        end
        k = k + 2;
    end
    switch creg
        case 'nc',   deterministe = zeros(T, 0);
        case 'c',    deterministe = ones(T, 1);
        case 'ct',   deterministe = [ones(T, 1), (1:T).'];
        case 'ctt',  deterministe = [ones(T, 1), (1:T).', ((1:T).') .^ 2];
        otherwise
            error('econ:egcitest:Creg', ...
                  'La régression de cointégration vaut ''nc'', ''c'', ''ct'' ou ''ctt''.');
    end
    if isempty(vecteur)
        X = [deterministe, Y(:, 2:end)];
        coefficients = X \ Y(:, 1);
        residus = Y(:, 1) - X * coefficients;
        regresseurs = n - 1;
    else
        if numel(vecteur) ~= n
            error('econ:egcitest:Cvec', ...
                  'Le vecteur de cointégration doit avoir %d composantes.', n);
        end
        coefficients = vecteur;
        brut = Y * vecteur;
        if isempty(deterministe)
            residus = brut;
        else
            residus = brut - deterministe * (deterministe \ brut);
        end
        % Le vecteur n'a pas été estimé : le test redevient celui d'une
        % racine unitaire ordinaire.
        regresseurs = 0;
    end
    regression = struct('coefficients', coefficients, 'residus', residus, ...
                        'creg', creg, 'regresseurs', regresseurs);
    switch rreg
        case 'adf'
            [statistique, coefficientsResiduels] = ...
                matlibre_dickey_fuller(residus, retards, 'ar', forme);
        case 'pp'
            [statistique, coefficientsResiduels] = ...
                matlibre_phillips_perron(residus, retards, 'ar', forme);
        otherwise
            error('econ:egcitest:Rreg', ...
                  'Le test des résidus vaut ''adf'' ou ''pp'', pas ''%s''.', rreg);
    end
    residuelle = struct('coefficients', coefficientsResiduels, ...
                        'rreg', rreg, 'lags', retards, 'test', forme);
    [pValeur, valeurCritique] = ...
        matlibre_egci_table(statistique, creg, regresseurs, forme, alpha);
    rejet = statistique < valeurCritique;
end
