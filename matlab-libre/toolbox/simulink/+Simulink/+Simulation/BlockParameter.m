classdef BlockParameter
%BLOCKPARAMETER Un paramètre de bloc qu'un SimulationInput change.
%   P = SIMULINK.SIMULATION.BLOCKPARAMETER(CHEMIN,NOM,VALEUR) : le
%   paramètre NOM du bloc CHEMIN — « modele/bloc » — vaudra VALEUR le
%   temps d'une simulation, le modèle restant tel qu'il est. C'est ce que
%   SETBLOCKPARAMETER range dans la propriété BlockParameters d'un
%   SIMULINK.SIMULATIONINPUT.
%
%   Exemple :
%      p = Simulink.Simulation.BlockParameter('m/k', 'Gain', '5');
%      p.Name                             % 'Gain'
%
%   Voir aussi SIMULINK.SIMULATIONINPUT, SET_PARAM.
    properties
        BlockPath = ''
        Name = ''
        Value = []
    end
    methods
        function obj = BlockParameter(chemin, nom, valeur)
            if nargin == 0
                return
            end
            if nargin < 3
                error('Simulink:Simulation:InvalidNumberOfArguments', ...
                      'Un parametre de bloc se donne par un chemin, un nom et une valeur.');
            end
            obj.BlockPath = texte(chemin, 'Le chemin d''un bloc');
            obj.Name = texte(nom, 'Le nom d''un parametre de bloc');
            obj.Value = valeur;
        end
    end
end

function t = texte(v, quoi)
    if ~((ischar(v) && isrow(v)) || (isstring(v) && isscalar(v))) || strlength(string(v)) == 0
        error('Simulink:Simulation:InvalidBlockParameter', '%s est un texte non vide.', quoi);
    end
    t = char(v);
end
