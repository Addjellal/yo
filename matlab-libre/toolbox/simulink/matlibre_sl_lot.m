function sorties = matlibre_sl_lot(mode, entrees, modeles, varargin)
%MATLIBRE_SL_LOT Fait les simulations que décrivent des SimulationInput.
%   OUT = MATLIBRE_SL_LOT('sim',IN,MODELES,...) est ce que fait SIM(IN) ;
%   OUT = MATLIBRE_SL_LOT('parsim',IN,MODELES,...) ce que fait PARSIM(IN).
%   MODELES{K} est le modèle de IN(K) quand l'appelant l'a trouvé — une
%   variable de son espace qui porte le nom du modèle —, vide sinon : le
%   modèle est alors celui que le SimulationInput porte, ou celui d'un
%   modèle ouvert, d'une variable de base ou d'un fichier de ce nom.
%   MATLIBRE_SL_LOT('valider',IN,{[]}) vérifie sans simuler.
%
%   Pour chaque simulation : PreSimFcn, puis les réglages et les
%   paramètres de blocs posés sur une copie du modèle, les variables
%   posées dans l'espace de travail de base, la simulation, l'espace de
%   base rendu tel qu'il était, et PostSimFcn. Une erreur est rangée dans
%   ErrorMessage — sauf pour SIM d'un seul SimulationInput sans
%   'CaptureErrors' à 'on', où elle part comme celle de SIM.
%
%   Options de 'sim' : CaptureErrors, StopOnError, ShowProgress ('off').
%   Options de 'parsim' : ShowProgress ('on'), StopOnError, SetupFcn,
%   CleanupFcn ; TransferBaseWorkspaceVariables, UseFastRestart,
%   ShowSimulationManager, AttachedFiles, ManageDependencies sont admises
%   sans effet — tout se passe dans la même session.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
%
%   Exemple :
%      m = add_block(new_system('m'), 'constant', 'c', 'Value', 'K');
%      m = add_line(add_block(m, 'outport', 'y'), 'c', 'y');
%      in = Simulink.SimulationInput(m);
%      in = in.setVariable('K', 7);
%      out = matlibre_sl_lot('sim', in, {[]});
%      out.yout(end)                      % 7
%
%   Voir aussi SIM, PARSIM, SIMULINK.SIMULATIONINPUT.
    if ~isa(entrees, 'Simulink.SimulationInput')
        error('Simulink:Simulation:InvalidSimulationInput', ...
              'On attend un Simulink.SimulationInput, ou un tableau de ceux-ci.');
    end
    if strcmp(mode, 'valider')
        modele = resoudre(entrees, modeles{1});
        appliquer(modele, entrees);
        sorties = [];
        return
    end
    options = lireOptions(mode, varargin, numel(entrees));
    n = numel(entrees);
    resultats = cell(1, n);
    if ~isempty(options.SetupFcn)
        options.SetupFcn();
    end
    progres(options, 'debut', n);
    echecs = 0;
    arrete = false;
    for k = 1:n
        if arrete
            resultats{k} = struct('ErrorMessage', ...
                ['La simulation n''a pas ete lancee : une simulation precedente a echoue, ' ...
                 'et StopOnError vaut ''on''.'], ...
                'SimulationMetadata', metadonnees(entrees(k), [], false, []));
            continue
        end
        try
            resultats{k} = executer(entrees(k), modeles{k}, options.capturer);
        catch err
            if ~isempty(options.CleanupFcn)
                options.CleanupFcn();
            end
            rethrow(err);
        end
        if ~isempty(resultats{k}.ErrorMessage)
            echecs = echecs + 1;
            arrete = options.StopOnError;
        end
        progres(options, 'fin', n, k, resultats{k}.ErrorMessage);
    end
    progres(options, 'bilan', n, echecs);
    if ~isempty(options.CleanupFcn)
        options.CleanupFcn();
    end
    sorties = assembler(resultats, size(entrees));
end

function options = lireOptions(mode, args, n)
    options = struct('capturer', true, 'StopOnError', false, 'ShowProgress', false, ...
                     'SetupFcn', [], 'CleanupFcn', []);
    capturer = 'off';
    if strcmp(mode, 'parsim')
        options.ShowProgress = true;
        admises = {'ShowProgress', 'StopOnError', 'SetupFcn', 'CleanupFcn', ...
                   'TransferBaseWorkspaceVariables', 'UseFastRestart', ...
                   'ShowSimulationManager', 'AttachedFiles', 'ManageDependencies', ...
                   'RunInBackground'};
        fonction = 'PARSIM';
    else
        admises = {'CaptureErrors', 'StopOnError', 'ShowProgress', 'UseFastRestart', ...
                   'ShowSimulationManager', 'TransferBaseWorkspaceVariables', ...
                   'ManageDependencies', 'AttachedFiles'};
        fonction = 'SIM';
    end
    if mod(numel(args), 2) ~= 0
        error('Simulink:Commands:SimArguments', ...
              '%s(IN,...) : les options vont par paires, un nom et une valeur.', fonction);
    end
    for k = 1:2:numel(args)
        nom = args{k};
        trouve = [];
        if ischar(nom) || (isstring(nom) && isscalar(nom))
            trouve = find(strcmpi(char(nom), admises), 1);
        end
        if isempty(trouve)
            error('Simulink:Commands:SimArguments', ...
                  ['%s(IN,...) n''a pas d''option ''%s'' ; ses options sont : %s. Les ' ...
                   'reglages du modele se posent par SETMODELPARAMETER.'], fonction, ...
                  texte(nom), strjoin(admises, ', '));
        end
        nom = admises{trouve};
        valeur = args{k + 1};
        switch nom
            case {'SetupFcn', 'CleanupFcn'}
                if ~isa(valeur, 'function_handle') && ~(isnumeric(valeur) && isempty(valeur))
                    error('Simulink:Commands:SimArguments', ...
                          '%s est une poignee de fonction sans argument, @f.', nom);
                end
                options.(nom) = valeur;
            case 'CaptureErrors'
                capturer = interrupteur(nom, valeur);
            case {'StopOnError', 'ShowProgress'}
                options.(nom) = strcmp(interrupteur(nom, valeur), 'on');
            case 'RunInBackground'
                if strcmp(interrupteur(nom, valeur), 'on')
                    error('Simulink:parsim:RunInBackgroundUnsupported', ...
                          ['MatLibre n''a pas de pool parallele : PARSIM fait ses ' ...
                           'simulations au premier plan, l''une apres l''autre. Retirez ' ...
                           '''RunInBackground''.']);
                end
            otherwise
                % admise, sans effet : une seule session fait tout
        end
    end
    % SIM d'un seul SimulationInput laisse partir l'erreur, comme SIM(NOM) ;
    % un tableau la range dans ErrorMessage pour que les autres se fassent.
    if strcmp(mode, 'sim') && n == 1
        options.capturer = strcmp(capturer, 'on');
    end
end

function v = interrupteur(nom, v)
    if islogical(v) || isnumeric(v)
        if isscalar(v) && (v == 0 || v == 1)
            admis = {'off', 'on'};
            v = admis{double(v) + 1};
            return
        end
    elseif (ischar(v) || (isstring(v) && isscalar(v))) && any(strcmpi(char(v), {'on', 'off'}))
        v = lower(char(v));
        return
    end
    error('Simulink:Commands:SimArguments', 'L''option %s vaut ''on'' ou ''off''.', nom);
end

function t = texte(v)
    if ischar(v) || isstring(v)
        t = char(v);
    else
        t = class(v);
    end
end

function progres(options, etape, n, varargin)
    if ~options.ShowProgress
        return
    end
    instant = datestr(now, 'dd-mmm-yyyy HH:MM:SS');
    switch etape
        case 'debut'
            fprintf('[%s] %d simulation(s) a faire, l''une apres l''autre.\n', instant, n);
        case 'fin'
            [k, message] = varargin{:};
            if isempty(message)
                fprintf('[%s] Simulation %d sur %d terminee.\n', instant, k, n);
            else
                fprintf('[%s] Simulation %d sur %d en erreur : %s\n', instant, k, n, message);
            end
        case 'bilan'
            fprintf('[%s] %d simulation(s) faite(s), %d en erreur.\n', instant, n, varargin{1});
    end
end

function sortie = executer(entree, modele, capturer)
    avant = [];
    debut = tic;
    try
        entree = appelerAvant(entree);
        modele = resoudre(entree, modele);
        modele = appliquer(modele, entree);
        avant = poserVariables(entree.Variables);
        if isempty(entree.ExternalInput)
            resultat = sim(modele);
        else
            resultat = sim(modele, [], [], entree.ExternalInput);
        end
        restaurer(avant);
        avant = [];
        resultat.ErrorMessage = '';
        resultat.SimulationMetadata = metadonnees(entree, modele, true, toc(debut));
        sortie = appelerApres(entree, resultat);
    catch err
        restaurer(avant);
        if ~capturer
            rethrow(err);
        end
        sortie = struct('ErrorMessage', err.message, ...
                        'SimulationMetadata', metadonnees(entree, [], false, toc(debut), err));
    end
end

% Le modèle : celui que l'appelant a trouvé, celui que porte le
% SimulationInput, ou celui qui porte son nom.
function modele = resoudre(entree, modele)
    if ~isempty(entree.ModeleDonne)
        modele = entree.ModeleDonne;
    end
    if ~isempty(modele)
        return
    end
    if isempty(entree.ModelName)
        error('Simulink:Simulation:ModelNameMissing', ...
              ['Ce SimulationInput ne nomme pas de modele : creez-le par ' ...
               'Simulink.SimulationInput(NOM).']);
    end
    modele = matlibre_sl_modele(entree.ModelName);
end

function modele = appliquer(modele, entree)
    for k = 1:numel(entree.ModelParameters)
        p = entree.ModelParameters(k);
        modele = set_param(modele, p.Name, p.Value);
    end
    if ~isempty(entree.InitialState)
        modele = set_param(modele, 'LoadInitialState', 'on', 'InitialState', entree.InitialState);
    end
    prefixe = [char(modele.nom) '/'];
    for k = 1:numel(entree.BlockParameters)
        p = entree.BlockParameters(k);
        if ~strncmp(p.BlockPath, prefixe, numel(prefixe))
            error('Simulink:Commands:InvSimulinkObjectName', ...
                  ['Le SimulationInput change le parametre ''%s'' du bloc ''%s'', qui ' ...
                   'n''est pas dans le modele ''%s'' : le chemin d''un bloc commence par ' ...
                   'le nom de son modele.'], p.Name, p.BlockPath, char(modele.nom));
        end
        try
            modele = set_param(modele, p.BlockPath, p.Name, p.Value);
        catch err
            if strcmp(err.identifier, 'Simulink:Commands:InvSimulinkObjectName')
                error('Simulink:Commands:InvSimulinkObjectName', ...
                      ['Le SimulationInput change le parametre ''%s'' du bloc ''%s'', ' ...
                       'que le modele ''%s'' n''a pas.'], p.Name, p.BlockPath, ...
                      char(modele.nom));
            end
            rethrow(err);
        end
    end
end

% PreSimFcn reçoit le SimulationInput ; s'il en rend un, c'est lui qui
% est simulé.
function entree = appelerAvant(entree)
    f = entree.PreSimFcn;
    if isempty(f)
        return
    end
    nouvelle = appeler(f, entree);
    if ~isempty(nouvelle)
        if ~isa(nouvelle, 'Simulink.SimulationInput') || numel(nouvelle) ~= 1
            error('Simulink:Simulation:InvalidPreSimFcnOutput', ...
                  'PreSimFcn rend un Simulink.SimulationInput, ou rien ; pas un %s.', ...
                  class(nouvelle));
        end
        entree = nouvelle;
    end
end

% PostSimFcn reçoit le résultat ; une structure qu'il rend devient le
% résultat, que complètent ErrorMessage et SimulationMetadata.
function sortie = appelerApres(entree, resultat)
    sortie = resultat;
    f = entree.PostSimFcn;
    if isempty(f)
        return
    end
    nouvelle = appeler(f, resultat);
    if isempty(nouvelle) && ~isstruct(nouvelle)
        return
    end
    if ~isstruct(nouvelle) || numel(nouvelle) ~= 1
        error('Simulink:Simulation:InvalidPostSimFcnOutput', ...
              'PostSimFcn rend une structure, ou rien ; pas un %s.', class(nouvelle));
    end
    sortie = nouvelle;
    sortie.ErrorMessage = '';
    sortie.SimulationMetadata = resultat.SimulationMetadata;
end

% Une fonction qu'on appelle pour ce qu'elle rend, si elle rend quelque
% chose : une fonction sans sortie s'appelle sans en demander.
function r = appeler(f, argument)
    r = [];
    if nargout(f) == 0
        f(argument);
        return
    end
    try
        r = f(argument);
    catch err
        if ~any(strcmp(err.identifier, {'MATLAB:emptyOutput', 'MATLAB:outputArgUndefined', ...
                                        'MATLAB:TooManyOutputs'}))
            rethrow(err);
        end
        r = [];
    end
end

function avant = poserVariables(variables)
    avant = struct('nom', {}, 'existait', {}, 'valeur', {});
    for k = 1:numel(variables)
        nom = variables(k).Name;
        existait = evalin('base', sprintf('exist(''%s'', ''var'')', nom)) == 1;
        ancienne = [];
        if existait
            ancienne = evalin('base', nom);
        end
        avant(end + 1) = struct('nom', nom, 'existait', existait, 'valeur', {ancienne}); %#ok<AGROW>
        assignin('base', nom, variables(k).Value);
    end
end

function restaurer(avant)
    for k = numel(avant):-1:1
        if avant(k).existait
            assignin('base', avant(k).nom, avant(k).valeur);
        else
            evalin('base', sprintf('clear(''%s'')', avant(k).nom));
        end
    end
end

function m = metadonnees(entree, modele, reussi, duree, err)
    info = struct('ModelName', entree.ModelName);
    if ~isempty(modele)
        config = matlibre_sl_config('lire', modele);
        info.StartTime = config.StartTime;
        info.StopTime = config.StopTime;
        info.SolverInfo = struct('Type', config.SolverType, 'Solver', config.Solver);
    end
    execution = struct('StopEvent', 'ReachedStopTime', 'ErrorDiagnostic', []);
    if ~reussi
        execution.StopEvent = 'DiagnosticError';
        if nargin >= 5
            execution.ErrorDiagnostic = struct('identifier', err.identifier, ...
                                               'message', err.message);
        end
    end
    m = struct('ModelInfo', info, 'ExecutionInfo', execution, ...
               'TimingInfo', struct('TotalElapsedWallTime', duree), ...
               'UserString', entree.UserString);
end

% Des résultats aux champs différents — une simulation en erreur n'a que
% son message — font un tableau de structures : chacun reçoit les champs
% des autres, vides, et ErrorMessage et SimulationMetadata ferment la
% marche.
function sorties = assembler(resultats, taille)
    champs = {};
    for k = 1:numel(resultats)
        for nom = fieldnames(resultats{k}).'
            if ~any(strcmp(champs, nom{1})) && ...
               ~any(strcmp(nom{1}, {'ErrorMessage', 'SimulationMetadata'}))
                champs{end + 1} = nom{1}; %#ok<AGROW>
            end
        end
    end
    champs = [champs, {'ErrorMessage', 'SimulationMetadata'}];
    liste = cell(1, numel(resultats));
    for k = 1:numel(resultats)
        s = struct();
        for i = 1:numel(champs)
            if isfield(resultats{k}, champs{i})
                s.(champs{i}) = resultats{k}.(champs{i});
            else
                s.(champs{i}) = [];
            end
        end
        liste{k} = s;
    end
    sorties = reshape([liste{:}], taille);
end
