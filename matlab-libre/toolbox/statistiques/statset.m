function options = statset(varargin)
%STATSET Structure d'options des fonctions statistiques.
%   OPTIONS = STATSET('nom1',valeur1,'nom2',valeur2,...) construit la
%   structure d'options que prennent les fonctions d'ajustement de la
%   boîte à outils : NLINFIT, MLE, KMEANS, entre autres.
%
%   OPTIONS = STATSET sans argument rend la structure par défaut, tous
%   les champs vides : chaque fonction emploie alors sa propre valeur.
%
%   OPTIONS = STATSET(ANCIENNES,'nom',valeur,...) part d'une structure
%   existante et n'en change que ce qui est nommé.
%
%   OPTIONS = STATSET('nlinfit') rend les valeurs par défaut de la
%   fonction nommée — 'nlinfit' et 'fitnlm' (MaxIter 100, TolFun et TolX
%   1e-8, DerivStep eps^(1/3)), 'kmeans', 'mle', 'fitgmdist' —, qu'on
%   modifie ensuite champ par champ.
%
%   V = STATSET(OPTIONS,'nom') n'est pas la forme de MATLAB ; pour lire
%   un champ, employez STATGET.
%
%   Les champs reconnus :
%      Display        'off', 'final' ou 'iter' ;
%      MaxIter        nombre maximal d'itérations ;
%      MaxFunEvals    nombre maximal d'évaluations ;
%      TolFun         tolérance sur la fonction ;
%      TolX           tolérance sur les paramètres ;
%      TolBnd         tolérance sur les bornes ;
%      GradObj        'on' si le gradient est fourni ;
%      DerivStep      pas des différences finies ;
%      FunValCheck    'on' pour refuser un NaN ou un infini ;
%      Robust         'on' pour un ajustement robuste ;
%      WgtFun         fonction de poids, si Robust vaut 'on' ;
%      Tune           constante de réglage de cette fonction ;
%      Streams, UseParallel, UseSubstreams : acceptés, sans effet.
%
%   Exemples :
%      options = statset('MaxIter', 1000, 'TolFun', 1e-12);
%      rng(1);
%      x = linspace(0, 2, 40)';
%      y = 3 * exp(-1.5 * x) + 0.01 * randn(40, 1);
%      b = nlinfit(x, y, @(p, t) p(1) * exp(-p(2) * t), [1 1], options);
%
%      serrees = statset(options, 'TolX', 1e-14);
%
%      parDefaut = statset('nlinfit');
%      parDefaut.MaxIter              % 100
%
%   Voir aussi STATGET, NLINFIT, MLE, KMEANS, OPTIMSET.
    noms = {'Display', 'MaxFunEvals', 'MaxIter', 'TolBnd', 'TolFun', ...
            'TolTypeFun', 'TolX', 'TolTypeX', 'GradObj', 'Jacobian', ...
            'DerivStep', 'FunValCheck', 'Robust', 'RobustWgtFun', 'WgtFun', ...
            'Tune', 'UseParallel', 'UseSubstreams', 'Streams', 'OutputFcn'};
    options = struct();
    debut = 1;
    if numel(varargin) >= 1 && isstruct(varargin{1})
        options = varargin{1};
        debut = 2;
    elseif numel(varargin) == 1 && (ischar(varargin{1}) || isstring(varargin{1}))
        options = defautsDe(char(varargin{1}), noms);
        return
    end
    for i = 1:numel(noms)
        if ~isfield(options, noms{i})
            options.(noms{i}) = [];
        end
    end
    k = debut;
    while k + 1 <= numel(varargin)
        nom = char(varargin{k});
        rang = 0;
        for i = 1:numel(noms)
            if strcmpi(nom, noms{i})
                rang = i;
                break;
            end
        end
        if rang == 0
            error('stats:statset:BadParamName', ...
                  'Unknown option ''%s''.', nom);
        end
        options.(noms{rang}) = varargin{k + 1};
        k = k + 2;
    end
    if k <= numel(varargin)
        error('stats:statset:BadInput', 'Options must come in name-value pairs.');
    end
end

function options = defautsDe(fonction, noms)
%DEFAUTSDE Les réglages par défaut d'une fonction, comme STATSET(NOM).
    options = struct();
    for i = 1:numel(noms)
        options.(noms{i}) = [];
    end
    options.Streams = {};
    switch lower(fonction)
        case {'nlinfit', 'fitnlm'}
            options.Display = 'off';
            options.MaxIter = 100;
            options.TolFun = 1e-8;
            options.TolX = 1e-8;
            options.DerivStep = eps ^ (1 / 3);
            options.FunValCheck = 'on';
            options.Robust = 'off';
            options.WgtFun = 'bisquare';
        case 'kmeans'
            options.Display = 'notify';
            options.MaxIter = 100;
        case 'mle'
            options.Display = 'off';
            options.MaxFunEvals = 200;
            options.MaxIter = 100;
            options.TolBnd = 1e-6;
            options.TolFun = 1e-6;
            options.TolX = 1e-6;
            options.GradObj = 'off';
            options.DerivStep = eps ^ (1 / 3);
            options.FunValCheck = 'on';
        case {'fitgmdist', 'gmdistribution'}
            options.Display = 'off';
            options.MaxIter = 100;
            options.TolFun = 1e-6;
        otherwise
            error('stats:statset:BadFunName', ...
                  ['STATSET : pas de réglages par défaut connus pour ''%s'' ', ...
                   '(nlinfit, fitnlm, kmeans, mle, fitgmdist).'], fonction);
    end
end
