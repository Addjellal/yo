function varargout = matlibre_sl_config(action, varargin)
%MATLIBRE_SL_CONFIG Les réglages d'un modèle : solveur, instants, diagnostics.
%   C = MATLIBRE_SL_CONFIG('lire',MODELE) rend la configuration complète
%   du modèle : chaque réglage qu'il porte, et la valeur par défaut de
%   ceux qu'il ne porte pas. C'est ce que SIM applique, et ce que la boîte
%   « Paramètres de configuration » de l'éditeur montre.
%
%   NOM = MATLIBRE_SL_CONFIG('nom',NOM) rend l'écriture canonique d'un
%   réglage — la casse est indifférente, comme dans Simulink — ou '' s'il
%   n'existe pas.
%
%   V = MATLIBRE_SL_CONFIG('valider',NOM,V) vérifie une valeur avant
%   qu'on la pose, et la rend sous sa forme canonique : un nom de solveur
%   inconnu, ou connu de Simulink mais pas encore écrit ici, est refusé en
%   le nommant plutôt que rangé pour rien.
%
%   S = MATLIBRE_SL_CONFIG('solveurs') rend la liste des solveurs
%   disponibles, en deux champs : fixe et variable.
%
%   Les réglages reconnus, avec leur valeur par défaut :
%     StartTime            0          l'instant initial
%     StopTime             10         l'instant final
%     SolverType           'Fixed-step'  ou 'Variable-step'
%     Solver               'ode1'     le solveur : ode1 à ode5, ou
%                                     FixedStepDiscrete sans état continu
%     FixedStep            0.01       le pas, en pas fixe
%     MaxStep, MinStep, InitialStep   'auto'  bornes du pas variable
%     RelTol               1e-3       tolérance relative du pas variable
%     AbsTol               'auto'     tolérance absolue du pas variable
%     ZeroCrossControl     'UseLocalSettings'  détection des passages par zéro
%     AlgebraicLoopMsg     'warning'  boucle algébrique : none, warning, error
%     UnconnectedInputMsg  'warning'  entrée non reliée : none, warning, error
%     UnconnectedOutputMsg 'none'     sortie non reliée : none, warning, error
%
%   MatLibre part du pas fixe et d'Euler, là où Simulink part du pas
%   variable : les modèles écrits avant que le pas variable n'existe
%   gardent ainsi leur comportement.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
%
%   Exemple :
%      c = matlibre_sl_config('lire', new_system('m'));
%      c.Solver                                   % 'ode1'
%      matlibre_sl_config('nom', 'reltol')        % 'RelTol'
%
%   Voir aussi SET_PARAM, GET_PARAM, SIM, SIMSET.
    switch lower(char(action))
        case 'lire'
            varargout{1} = lire(varargin{1});
        case 'nom'
            varargout{1} = nomCanonique(varargin{1});
        case 'valider'
            varargout{1} = valider(varargin{1}, varargin{2});
        case 'solveurs'
            varargout{1} = solveurs();
        case 'defauts'
            varargout{1} = defauts();
        otherwise
            error('Simulink:Config:Action', 'Action inconnue : %s.', char(action));
    end
end

function d = defauts()
    d = struct('StartTime', 0, 'StopTime', 10, 'SolverType', 'Fixed-step', ...
               'Solver', 'ode1', 'FixedStep', 0.01, 'MaxStep', 'auto', ...
               'MinStep', 'auto', 'InitialStep', 'auto', 'RelTol', 1e-3, ...
               'AbsTol', 'auto', 'ZeroCrossControl', 'UseLocalSettings', ...
               'AlgebraicLoopMsg', 'warning', 'UnconnectedInputMsg', 'warning', ...
               'UnconnectedOutputMsg', 'none');
end

% Les solveurs écrits ici. Simulink en a d'autres : ils sont refusés en
% le disant, au lieu d'être acceptés et remplacés en silence.
function s = solveurs()
    s = struct('fixe', {{'ode1', 'ode2', 'ode3', 'ode4', 'ode5', 'FixedStepDiscrete'}}, ...
               'variable', {{}});
end

function c = lire(modele)
    c = defauts();
    if ~isfield(modele, 'parametres') || isempty(modele.parametres)
        return
    end
    champs = fieldnames(modele.parametres);
    for k = 1:numel(champs)
        nom = nomCanonique(champs{k});
        if isempty(nom)
            continue   % un réglage propre au modèle, posé par ADD_PARAM
        end
        c.(nom) = modele.parametres.(champs{k});
    end
    % Le type suit le solveur quand on n'a donné que lui : « ode45 » est à
    % pas variable sans qu'on ait à le redire.
    if ~isfield(modele.parametres, 'SolverType') && isfield(c, 'Solver')
        c.SolverType = typeDe(c.Solver, c.SolverType);
    end
end

function nom = nomCanonique(demande)
    nom = '';
    noms = fieldnames(defauts());
    for k = 1:numel(noms)
        if strcmpi(noms{k}, char(demande))
            nom = noms{k};
            return
        end
    end
end

function t = typeDe(solveur, parDefaut)
    t = parDefaut;
    liste = solveurs();
    if any(strcmpi(solveur, liste.variable))
        t = 'Variable-step';
    elseif any(strcmpi(solveur, liste.fixe))
        t = 'Fixed-step';
    end
end

function v = valider(nom, v)
    nom = nomCanonique(nom);
    switch nom
        case 'Solver'
            liste = solveurs();
            connus = [liste.fixe, liste.variable];
            v = char(v);
            trouve = find(strcmpi(v, connus), 1);
            if isempty(trouve)
                simulinkSeul = {'ode8', 'ode14x', 'ode45', 'ode23', 'ode113', ...
                                'ode15s', 'ode23s', 'ode23t', 'ode23tb', ...
                                'VariableStepDiscrete', 'VariableStepAuto', ...
                                'FixedStepAuto'};
                if any(strcmpi(v, simulinkSeul))
                    error('Simulink:Commands:SolveurInconnu', ...
                          ['Le solveur ''%s'' est un solveur de Simulink que MatLibre ' ...
                           'n''a pas encore ; les solveurs disponibles sont : %s.'], ...
                          v, strjoin(connus, ', '));
                end
                error('Simulink:Commands:SolveurInconnu', ...
                      'Le solveur ''%s'' est inconnu ; les solveurs disponibles sont : %s.', ...
                      v, strjoin(connus, ', '));
            end
            v = connus{trouve};
        case 'SolverType'
            v = choix(nom, v, {'Fixed-step', 'Variable-step'});
        case {'AlgebraicLoopMsg', 'UnconnectedInputMsg', 'UnconnectedOutputMsg'}
            v = choix(nom, v, {'none', 'warning', 'error'});
        case 'ZeroCrossControl'
            v = choix(nom, v, {'UseLocalSettings', 'EnableAll', 'DisableAll'});
        case {'StartTime', 'StopTime', 'FixedStep', 'RelTol'}
            v = nombre(nom, v, false);
        case {'MaxStep', 'MinStep', 'InitialStep', 'AbsTol'}
            v = nombre(nom, v, true);
        case ''
            error('Simulink:Commands:ParamUnknown', ...
                  'Le modele n''a pas de reglage nomme ''%s''.', char(nom));
    end
end

function v = choix(nom, v, admis)
    trouve = find(strcmpi(char(v), admis), 1);
    if isempty(trouve)
        error('Simulink:Config:InvalidValue', ...
              'Le reglage %s vaut l''une de ces valeurs : %s ; pas ''%s''.', ...
              nom, strjoin(admis, ', '), char(v));
    end
    v = admis{trouve};
end

% Un nombre, ou l'expression qui le donne ; « auto » là où Simulink
% l'admet. Une expression reste texte : elle s'évalue au moment de simuler,
% comme un paramètre de bloc.
function v = nombre(nom, v, autoPermis)
    if ischar(v) || isstring(v)
        texte = char(v);
        if autoPermis && strcmpi(texte, 'auto')
            v = 'auto';
            return
        end
        valeur = str2double(texte);
        if ~isnan(valeur)
            v = valeur;
        end
        return
    end
    if ~(isnumeric(v) && isscalar(v) && isreal(v)) || isnan(v)
        error('Simulink:Config:InvalidValue', ...
              'Le reglage %s est un nombre reel.', nom);
    end
    v = double(v);
end
