classdef constraintAiming
%CONSTRAINTAIMING Contrainte de visée : pointer l'axe z vers un point.
%   C = CONSTRAINTAIMING(CORPS) demande que l'axe z de CORPS pointe vers
%   TargetPoint, à AngularTolerance près.
%
%   Propriétés :
%      EndEffector        - le corps qui vise
%      ReferenceBody      - le repère où le point est donné
%      TargetPoint        - le point visé, [X Y Z]
%      AngularTolerance   - l'écart angulaire toléré, en radians
%      Weights            - le poids de la contrainte
%
%   Viser laisse libre la rotation autour de l'axe de visée : c'est un
%   degré de liberté de moins contraint qu'une orientation complète, et
%   c'est exactement ce qu'il faut pour une caméra ou un outil de
%   révolution.
%
%   Exemple :
%      c = constraintAiming('camera');
%      c.TargetPoint = [1 0 0.5];
%
%   Voir aussi CONSTRAINTORIENTATIONTARGET, GENERALIZEDINVERSEKINEMATICS.
    properties
        EndEffector = ''
        ReferenceBody = ''
        TargetPoint = [0 0 0]
        AngularTolerance = 0
        Weights = 1
    end
    methods
        function obj = constraintAiming(corps, varargin)
            if nargin > 0
                obj.EndEffector = char(corps);
            end
            for k = 1:2:numel(varargin)
                obj.(varargin{k}) = varargin{k+1};
            end
        end
        function r = matlibre_residu(obj, robot, config)
            T = matlibre_rob_poseRelative(robot, config, obj.EndEffector, obj.ReferenceBody);
            vise = obj.TargetPoint(:) - T(1:3,4);
            if norm(vise) < eps
                r = 0;
                return
            end
            axe = T(1:3, 3);
            cosinus = min(max(dot(axe, vise / norm(vise)), -1), 1);
            r = obj.Weights * max(acos(cosinus) - obj.AngularTolerance, 0);
        end
    end
end
