function options = optimoptions(solveur, varargin)
%OPTIMOPTIONS Options d'un solveur d'optimisation.
%   OPTIONS = OPTIMOPTIONS('fmincon','Display','iter','MaxIterations',100)
%   rend une structure d'options. Les noms modernes et les anciens sont
%   acceptés, en écriture comme en lecture : MaxIterations ou MaxIter,
%   MaxFunctionEvaluations ou MaxFunEvals, OptimalityTolerance ou TolFun,
%   StepTolerance ou TolX, ConstraintTolerance ou TolCon. La structure
%   rendue porte les deux orthographes, tenues égales : le code écrit
%   pour l'une ou pour l'autre lit la même valeur.
%
%   Exemple :
%      o = optimoptions('fmincon', 'MaxIterations', 100);
%      o.MaxIterations                % 100
%      ancien = optimoptions('fminunc', 'TolFun', 1e-8);
%      ancien.OptimalityTolerance     % 1e-8 : les deux noms se rejoignent
%
%   Voir aussi OPTIMSET, OPTIMGET, FMINCON, LINPROG, LSQNONLIN.
    if nargin >= 1 && (isstruct(solveur))
        options = solveur;
        debut = 1;
    else
        options = struct('Solver', '', 'Display', 'final', 'MaxIter', 400, ...
                         'MaxFunEvals', 4000, 'TolX', 1e-10, 'TolFun', 1e-10, ...
                         'Algorithm', 'default');
        if nargin >= 1 && (ischar(solveur) || isstring(solveur))
            options.Solver = char(solveur);
            debut = 1;
        else
            debut = 1;
        end
    end
    k = debut;
    while k + 1 <= numel(varargin)
        nom = char(varargin{k});
        valeur = varargin{k + 1};
        switch lower(nom)
            case {'maxiterations', 'maxiter'},        options.MaxIter = valeur;
            case {'maxfunctionevaluations', 'maxfunevals'}, options.MaxFunEvals = valeur;
            case {'optimalitytolerance', 'tolfun'},   options.TolFun = valeur;
            case {'steptolerance', 'tolx'},           options.TolX = valeur;
            case {'constrainttolerance', 'tolcon'},   options.TolCon = valeur;
            case 'display',                           options.Display = char(valeur);
            case 'algorithm',                         options.Algorithm = char(valeur);
            otherwise,                                options.(nom) = valeur;
        end
        k = k + 2;
    end
    options = apparier(options);
end

function options = apparier(options)
%APPARIER Chaque réglage sous ses deux noms.
%   Les solveurs de MatLibre lisent les noms courts — MaxIter, TolFun —
%   et le code écrit pour MATLAB lit les longs. La structure porte donc
%   les deux, avec la même valeur : celle qui a été posée.
    couples = {'MaxIterations', 'MaxIter'; ...
               'MaxFunctionEvaluations', 'MaxFunEvals'; ...
               'OptimalityTolerance', 'TolFun'; ...
               'StepTolerance', 'TolX'; ...
               'ConstraintTolerance', 'TolCon'};
    for k = 1:size(couples, 1)
        long = couples{k, 1};
        court = couples{k, 2};
        if isfield(options, court)
            options.(long) = options.(court);
        elseif isfield(options, long)
            options.(court) = options.(long);
        end
    end
end
