classdef constraintPositionTarget
%CONSTRAINTPOSITIONTARGET Contrainte de position sur un corps.
%   C = CONSTRAINTPOSITIONTARGET(CORPS) demande que l'origine de CORPS
%   atteigne TargetPosition, sans rien imposer à son orientation.
%
%   Propriétés :
%      EndEffector        - le corps contraint
%      ReferenceBody      - le repère de référence, la base par défaut
%      TargetPosition     - le point visé, [X Y Z]
%      PositionTolerance  - l'écart toléré, en mètres
%      Weights            - le poids de la contrainte
%
%   Ne contraindre que la position laisse au solveur les degrés de liberté
%   d'orientation : c'est ce qu'on veut d'un bras redondant, dont on veut
%   fixer le point sans imposer la pose de l'outil.
%
%   Exemple :
%      c = constraintPositionTarget('effecteur');
%      c.TargetPosition = [0.4 0.2 0];
%
%   Voir aussi CONSTRAINTPOSETARGET, GENERALIZEDINVERSEKINEMATICS.
    properties
        EndEffector = ''
        ReferenceBody = ''
        TargetPosition = [0 0 0]
        PositionTolerance = 0
        Weights = 1
    end
    methods
        function obj = constraintPositionTarget(corps, varargin)
            if nargin > 0
                obj.EndEffector = char(corps);
            end
            for k = 1:2:numel(varargin)
                obj.(varargin{k}) = varargin{k+1};
            end
        end
        function r = matlibre_residu(obj, robot, config)
            T = matlibre_rob_poseRelative(robot, config, obj.EndEffector, obj.ReferenceBody);
            distance = norm(obj.TargetPosition(:) - T(1:3,4));
            r = obj.Weights * max(distance - obj.PositionTolerance, 0);
        end
    end
end
