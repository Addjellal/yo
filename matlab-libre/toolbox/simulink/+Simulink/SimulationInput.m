classdef SimulationInput
%SIMULATIONINPUT Ce qui change, le temps d'une simulation, dans un modèle.
%   IN = SIMULINK.SIMULATIONINPUT(NOM) prépare une simulation du modèle
%   NOM sans toucher au modèle : les variables, les paramètres de blocs et
%   les réglages qu'on y pose ne valent que pour elle. NOM est le nom du
%   modèle — celui d'une variable qui le porte, d'un modèle ouvert ou d'un
%   fichier —, ou le modèle lui-même, bâti par NEW_SYSTEM.
%
%   Chaque méthode rend l'objet modifié, qu'il faut ranger :
%      IN = IN.SETVARIABLE(NOM,VALEUR)          pose une variable dans
%                                               l'espace de travail de
%                                               base, pendant la simulation
%      IN = IN.SETBLOCKPARAMETER(BLOC,PARAM,V)  change un paramètre de bloc
%                                               (plusieurs triplets admis)
%      IN = IN.SETMODELPARAMETER(NOM,V)         change un réglage :
%                                               StopTime, Solver…
%      IN = IN.SETEXTERNALINPUT(U)              les entrées externes
%      IN = IN.SETINITIALSTATE(X0)              l'état initial (les états
%                                               continus, dans l'ordre de
%                                               xout)
%      IN = IN.SETPRESIMFCN(F)                  F(IN) avant la simulation ;
%                                               si F rend un SimulationInput,
%                                               c'est lui qui est simulé
%      IN = IN.SETPOSTSIMFCN(F)                 F(OUT) après ; si F rend une
%                                               structure, elle devient le
%                                               résultat
%   GETVARIABLE, GETBLOCKPARAMETER, GETMODELPARAMETER relisent ce qui est
%   posé ; REMOVEVARIABLE, REMOVEBLOCKPARAMETER, REMOVEMODELPARAMETER le
%   retirent ; VALIDATE(IN) vérifie, sans simuler, que le modèle existe et
%   que chaque bloc et chaque réglage nommés y sont.
%
%   OUT = SIM(IN) simule ; pour un tableau IN, les simulations se font
%   l'une après l'autre, comme par PARSIM, et OUT est le tableau de leurs
%   résultats. Chaque résultat porte, en plus de ce que rend SIM,
%   ErrorMessage — vide si tout s'est bien passé — et SimulationMetadata.
%   L'espace de travail de base retrouve ensuite ses variables.
%
%   Exemple :
%      m = new_system('m');
%      m = add_block(m, 'constant', 'c', 'Value', 'K');
%      m = add_block(m, 'gain', 'g', 'Gain', 2);
%      m = add_block(m, 'outport', 'y');
%      m = add_line(add_line(m, 'c', 'g'), 'g', 'y');
%      in = Simulink.SimulationInput('m');
%      in = in.setVariable('K', 5);
%      in = in.setBlockParameter('m/g', 'Gain', '3');
%      in = in.setModelParameter('StopTime', '1');
%      out = sim(in);
%      out.yout(end)                      % 15
%
%   Voir aussi PARSIM, SIM, SET_PARAM, SIMULINK.PARAMETER.
    properties
        ModelName = ''
        InitialState = []
        ExternalInput = []
        ModelParameters = Simulink.Simulation.ModelParameter.empty
        BlockParameters = Simulink.Simulation.BlockParameter.empty
        Variables = Simulink.Simulation.Variable.empty
        PreSimFcn = []
        PostSimFcn = []
        UserString = ''
    end
    properties (Hidden)
        % Le modèle lui-même, quand on l'a donné plutôt que son nom.
        ModeleDonne = []
    end
    methods
        function obj = SimulationInput(modele)
            if nargin == 0
                return
            end
            if isstruct(modele) && isfield(modele, 'blocs') && isfield(modele, 'nom')
                obj.ModelName = char(modele.nom);
                obj.ModeleDonne = modele;
            elseif ((ischar(modele) && isrow(modele)) || (isstring(modele) && isscalar(modele))) ...
                    && strlength(string(modele)) > 0
                obj.ModelName = char(modele);
            else
                error('Simulink:Simulation:InvalidModelName', ...
                      ['Un SimulationInput se cree pour un modele : son nom, ou le modele ' ...
                       'bati par NEW_SYSTEM.']);
            end
        end

        function obj = setVariable(obj, nom, valeur, varargin)
            if nargin < 3
                error('Simulink:Simulation:InvalidNumberOfArguments', ...
                      'SETVARIABLE(IN,NOM,VALEUR) : il faut un nom et une valeur.');
            end
            v = Simulink.Simulation.Variable(nom, valeur, varargin{:});
            k = obj.trouverVariable(v.Name, v.Workspace);
            if isempty(k)
                obj.Variables(end + 1) = v;
            else
                obj.Variables(k) = v;
            end
        end
        function valeur = getVariable(obj, nom, varargin)
            k = obj.trouverVariable(char(nom), espaceDe(varargin));
            if isempty(k)
                error('Simulink:Simulation:VariableNotFound', ...
                      'Ce SimulationInput ne pose pas de variable ''%s''.', char(nom));
            end
            valeur = obj.Variables(k).Value;
        end
        function obj = removeVariable(obj, nom, varargin)
            k = obj.trouverVariable(char(nom), espaceDe(varargin));
            if isempty(k)
                error('Simulink:Simulation:VariableNotFound', ...
                      'Ce SimulationInput ne pose pas de variable ''%s''.', char(nom));
            end
            obj.Variables(k) = [];
        end

        function obj = setBlockParameter(obj, varargin)
            if isempty(varargin) || mod(numel(varargin), 3) ~= 0
                error('Simulink:Simulation:InvalidNumberOfArguments', ...
                      ['SETBLOCKPARAMETER(IN,BLOC,PARAMETRE,VALEUR) : les parametres de ' ...
                       'blocs se donnent par triplets.']);
            end
            for i = 1:3:numel(varargin)
                p = Simulink.Simulation.BlockParameter(varargin{i:i + 2});
                k = obj.trouverBloc(p.BlockPath, p.Name);
                if isempty(k)
                    obj.BlockParameters(end + 1) = p;
                else
                    obj.BlockParameters(k) = p;
                end
            end
        end
        function valeur = getBlockParameter(obj, chemin, nom)
            k = obj.trouverBloc(char(chemin), char(nom));
            if isempty(k)
                error('Simulink:Simulation:BlockParameterNotFound', ...
                      'Ce SimulationInput ne change pas le parametre ''%s'' du bloc ''%s''.', ...
                      char(nom), char(chemin));
            end
            valeur = obj.BlockParameters(k).Value;
        end
        function obj = removeBlockParameter(obj, chemin, nom)
            k = obj.trouverBloc(char(chemin), char(nom));
            if isempty(k)
                error('Simulink:Simulation:BlockParameterNotFound', ...
                      'Ce SimulationInput ne change pas le parametre ''%s'' du bloc ''%s''.', ...
                      char(nom), char(chemin));
            end
            obj.BlockParameters(k) = [];
        end

        function obj = setModelParameter(obj, varargin)
            if isempty(varargin) || mod(numel(varargin), 2) ~= 0
                error('Simulink:Simulation:InvalidNumberOfArguments', ...
                      ['SETMODELPARAMETER(IN,NOM,VALEUR) : les reglages se donnent par ' ...
                       'paires.']);
            end
            for i = 1:2:numel(varargin)
                p = Simulink.Simulation.ModelParameter(varargin{i:i + 1});
                k = obj.trouverReglage(p.Name);
                if isempty(k)
                    obj.ModelParameters(end + 1) = p;
                else
                    obj.ModelParameters(k) = p;
                end
            end
        end
        function valeur = getModelParameter(obj, nom)
            k = obj.trouverReglage(char(nom));
            if isempty(k)
                error('Simulink:Simulation:ModelParameterNotFound', ...
                      'Ce SimulationInput ne change pas le reglage ''%s''.', char(nom));
            end
            valeur = obj.ModelParameters(k).Value;
        end
        function obj = removeModelParameter(obj, nom)
            k = obj.trouverReglage(char(nom));
            if isempty(k)
                error('Simulink:Simulation:ModelParameterNotFound', ...
                      'Ce SimulationInput ne change pas le reglage ''%s''.', char(nom));
            end
            obj.ModelParameters(k) = [];
        end

        function obj = setExternalInput(obj, u)
            obj.ExternalInput = u;
        end
        function obj = setInitialState(obj, x0)
            if ~(isnumeric(x0) || ischar(x0) || isstring(x0))
                error('Simulink:Simulation:InvalidInitialState', ...
                      ['L''etat initial est un vecteur — les etats continus, dans l''ordre ' ...
                       'de xout —, ou le nom d''une variable qui le porte.']);
            end
            obj.InitialState = x0;
        end
        function obj = setPreSimFcn(obj, f)
            obj.PreSimFcn = fonction(f, 'PreSimFcn');
        end
        function obj = setPostSimFcn(obj, f)
            obj.PostSimFcn = fonction(f, 'PostSimFcn');
        end
        function obj = set.UserString(obj, texte)
            if isstring(texte) && isscalar(texte)
                texte = char(texte);
            end
            if ~(ischar(texte) && (isempty(texte) || isrow(texte)))
                error('Simulink:Simulation:InvalidUserString', 'UserString est un texte.');
            end
            obj.UserString = texte;
        end

        function validate(obj)
            for k = 1:numel(obj)
                matlibre_sl_lot('valider', obj(k), {[]});
            end
        end

        function disp(obj)
            matlibre_sl_proprietes(obj, {'ModelName', 'InitialState', 'ExternalInput', ...
                                         'ModelParameters', 'BlockParameters', 'Variables', ...
                                         'PreSimFcn', 'PostSimFcn', 'UserString'});
        end
    end
    methods (Hidden)
        function k = trouverVariable(obj, nom, espace)
            k = [];
            for i = 1:numel(obj.Variables)
                if strcmp(obj.Variables(i).Name, nom) && ...
                   (isempty(espace) || strcmp(obj.Variables(i).Workspace, espace))
                    k = i;
                    return
                end
            end
        end
        function k = trouverBloc(obj, chemin, nom)
            k = [];
            for i = 1:numel(obj.BlockParameters)
                if strcmp(obj.BlockParameters(i).BlockPath, chemin) && ...
                   strcmpi(obj.BlockParameters(i).Name, nom)
                    k = i;
                    return
                end
            end
        end
        function k = trouverReglage(obj, nom)
            k = [];
            for i = 1:numel(obj.ModelParameters)
                if strcmpi(obj.ModelParameters(i).Name, nom)
                    k = i;
                    return
                end
            end
        end
    end
end

function espace = espaceDe(options)
    espace = 'global-workspace';
    if numel(options) >= 2 && strcmpi(char(options{1}), 'Workspace')
        espace = char(options{2});
    end
end

function f = fonction(f, nom)
    if ~isa(f, 'function_handle') && ~(isnumeric(f) && isempty(f))
        error('Simulink:Simulation:InvalidFunctionHandle', ...
              '%s est une poignee de fonction, @f, ou [] pour n''en pas avoir.', nom);
    end
end
