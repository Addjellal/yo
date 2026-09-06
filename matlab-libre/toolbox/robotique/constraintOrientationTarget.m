classdef constraintOrientationTarget
%CONSTRAINTORIENTATIONTARGET Contrainte d'orientation sur un corps.
%   C = CONSTRAINTORIENTATIONTARGET(CORPS) demande que CORPS prenne
%   l'orientation TargetOrientation, donnée en quaternion, sans rien
%   imposer à sa position.
%
%   Propriétés :
%      EndEffector           - le corps contraint
%      ReferenceBody         - le repère de référence
%      TargetOrientation     - le quaternion visé, [W X Y Z]
%      OrientationTolerance  - l'écart angulaire toléré, en radians
%      Weights               - le poids de la contrainte
%
%   Exemple :
%      c = constraintOrientationTarget('outil');
%      c.TargetOrientation = eul2quat([pi/2 0 0]);
%
%   Voir aussi CONSTRAINTPOSETARGET, GENERALIZEDINVERSEKINEMATICS.
    properties
        EndEffector = ''
        ReferenceBody = ''
        TargetOrientation = [1 0 0 0]
        OrientationTolerance = 0
        Weights = 1
    end
    methods
        function obj = constraintOrientationTarget(corps, varargin)
            if nargin > 0
                obj.EndEffector = char(corps);
            end
            for k = 1:2:numel(varargin)
                obj.(varargin{k}) = varargin{k+1};
            end
        end
        function r = matlibre_residu(obj, robot, config)
            T = matlibre_rob_poseRelative(robot, config, obj.EndEffector, obj.ReferenceBody);
            aa = rotm2axang(quat2rotm(obj.TargetOrientation) * T(1:3,1:3).');
            r = obj.Weights * max(abs(aa(4)) - obj.OrientationTolerance, 0);
        end
    end
end
