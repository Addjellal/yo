classdef ModelParameter
%MODELPARAMETER Un réglage de modèle qu'un SimulationInput change.
%   P = SIMULINK.SIMULATION.MODELPARAMETER(NOM,VALEUR) : le réglage NOM
%   du modèle — StopTime, Solver, FixedStep… — vaudra VALEUR le temps
%   d'une simulation. C'est ce que SETMODELPARAMETER range dans la
%   propriété ModelParameters d'un SIMULINK.SIMULATIONINPUT.
%
%   Exemple :
%      p = Simulink.Simulation.ModelParameter('StopTime', '20');
%      p.Value                            % '20'
%
%   Voir aussi SIMULINK.SIMULATIONINPUT, SET_PARAM.
    properties
        Name = ''
        Value = []
    end
    methods
        function obj = ModelParameter(nom, valeur)
            if nargin == 0
                return
            end
            if nargin < 2
                error('Simulink:Simulation:InvalidNumberOfArguments', ...
                      'A model parameter requires a name and a value.');
            end
            if ~((ischar(nom) && isrow(nom)) || (isstring(nom) && isscalar(nom))) || ...
               strlength(string(nom)) == 0
                error('Simulink:Simulation:InvalidModelParameter', ...
                      'The model parameter name must be nonempty text.');
            end
            obj.Name = char(nom);
            obj.Value = valeur;
        end
    end
end
