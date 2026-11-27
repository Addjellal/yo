classdef Variable
%VARIABLE Une variable qu'un SimulationInput pose pour sa simulation.
%   V = SIMULINK.SIMULATION.VARIABLE(NOM,VALEUR) ; V =
%   SIMULINK.SIMULATION.VARIABLE(NOM,VALEUR,'Workspace',ESPACE). ESPACE
%   vaut 'global-workspace', l'espace de travail de base, ou le nom du
%   modèle : la variable va alors dans son espace de travail, que les
%   paramètres de ses blocs lisent avant celui de base.
%   C'est ce que SETVARIABLE range dans la propriété Variables d'un
%   SIMULINK.SIMULATIONINPUT.
%
%   Exemple :
%      v = Simulink.Simulation.Variable('K', 3);
%      v.Workspace                        % 'global-workspace'
%
%   Voir aussi SIMULINK.SIMULATIONINPUT.
    properties
        Name = ''
        Value = []
        Workspace = 'global-workspace'
    end
    methods
        function obj = Variable(nom, valeur, varargin)
            if nargin == 0
                return
            end
            if ~((ischar(nom) && isvarname(nom)) || (isstring(nom) && isscalar(nom) && ...
                                                     isvarname(char(nom))))
                error('Simulink:Simulation:InvalidVariableName', ...
                      ['The simulation variable name must be a valid ' ...
                       'MATLAB variable name.']);
            end
            obj.Name = char(nom);
            if nargin > 1
                obj.Value = valeur;
            end
            if mod(numel(varargin), 2) ~= 0
                error('Simulink:Simulation:InvalidNumberOfArguments', ...
                      'Variable options must be name-value pairs: ''Workspace'', WORKSPACE.');
            end
            for k = 1:2:numel(varargin)
                if ~strcmpi(char(varargin{k}), 'Workspace')
                    error('Simulink:Simulation:InvalidOption', ...
                          'The only option of a simulation variable is ''Workspace''.');
                end
                espace = varargin{k + 1};
                if ~(ischar(espace) || (isstring(espace) && isscalar(espace))) || isempty(espace)
                    error('Simulink:Simulation:InvalidWorkspace', ...
                          ['The workspace of a variable must be ''global-workspace'' or the ' ...
                           'name ' ...
                           'of the model.']);
                end
                obj.Workspace = char(espace);
            end
        end
    end
end
