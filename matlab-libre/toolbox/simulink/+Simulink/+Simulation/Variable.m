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
                      ['Le nom d''une variable de simulation est un nom de variable ' ...
                       'MATLAB valide.']);
            end
            obj.Name = char(nom);
            if nargin > 1
                obj.Value = valeur;
            end
            if mod(numel(varargin), 2) ~= 0
                error('Simulink:Simulation:InvalidNumberOfArguments', ...
                      'Les options d''une variable vont par paires : ''Workspace'', ESPACE.');
            end
            for k = 1:2:numel(varargin)
                if ~strcmpi(char(varargin{k}), 'Workspace')
                    error('Simulink:Simulation:InvalidOption', ...
                          'Une variable de simulation n''a que l''option ''Workspace''.');
                end
                espace = varargin{k + 1};
                if ~(ischar(espace) || (isstring(espace) && isscalar(espace))) || isempty(espace)
                    error('Simulink:Simulation:InvalidWorkspace', ...
                          ['L''espace d''une variable est ''global-workspace'', ou le nom ' ...
                           'du modele.']);
                end
                obj.Workspace = char(espace);
            end
        end
    end
end
