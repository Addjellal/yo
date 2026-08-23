function options = optimoptions(solveur, varargin)
%OPTIMOPTIONS Options d'un solveur d'optimisation.
%   OPTIONS = OPTIMOPTIONS('fmincon','Display','iter','MaxIterations',100)
%   rend une structure d'options. Les noms modernes et les anciens sont
%   acceptés : MaxIterations ou MaxIter, OptimalityTolerance ou TolFun,
%   StepTolerance ou TolX.
%
%   Voir aussi OPTIMSET.
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
end
