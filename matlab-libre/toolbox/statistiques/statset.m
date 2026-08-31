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
%   V = STATSET(OPTIONS,'nom') n'est pas la forme de MATLAB ; pour lire
%   un champ, employez STATGET.
%
%   Les champs reconnus :
%      Display        'off', 'final' ou 'iter' ;
%      MaxIter        nombre maximal d'itérations ;
%      MaxFunEvals    nombre maximal d'évaluations ;
%      TolFun         tolérance sur la fonction ;
%      TolX           tolérance sur les paramètres ;
%      TolBound       tolérance sur les bornes ;
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
%      nlinfit(x, y, modele, depart, options);
%
%      serrees = statset(options, 'TolX', 1e-14);
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
