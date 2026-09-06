classdef constraintPoseTarget
%CONSTRAINTPOSETARGET Contrainte de pose complète sur un corps.
%   C = CONSTRAINTPOSETARGET(CORPS) demande que CORPS atteigne la pose
%   TargetTransform, exprimée dans le repère de ReferenceBody.
%
%   Propriétés :
%      EndEffector           - le corps contraint
%      ReferenceBody         - le repère de référence, la base par défaut
%      TargetTransform       - la pose visée, matrice 4x4
%      OrientationTolerance  - l'écart d'orientation toléré, en radians
%      PositionTolerance     - l'écart de position toléré, en mètres
%      Weights               - [orientation position]
%
%   Une tolérance non nulle donne du jeu : la contrainte n'est violée
%   qu'au-delà. C'est ce qui permet d'en satisfaire plusieurs à la fois
%   quand aucune configuration ne les vérifie exactement.
%
%   Exemple :
%      c = constraintPoseTarget('effecteur');
%      c.TargetTransform = trvec2tform([0.4 0.2 0]);
%
%   Voir aussi GENERALIZEDINVERSEKINEMATICS, CONSTRAINTPOSITIONTARGET.
    properties
        EndEffector = ''
        ReferenceBody = ''
        TargetTransform = eye(4)
        OrientationTolerance = 0
        PositionTolerance = 0
        Weights = [1 1]
    end
    methods
        function obj = constraintPoseTarget(corps, varargin)
            if nargin > 0
                obj.EndEffector = char(corps);
            end
            for k = 1:2:numel(varargin)
                obj.(varargin{k}) = varargin{k+1};
            end
        end
        function r = matlibre_residu(obj, robot, config)
        %MATLIBRE_RESIDU Écart pondéré : nul quand la contrainte est tenue.
            T = matlibre_rob_poseRelative(robot, config, obj.EndEffector, obj.ReferenceBody);
            aa = rotm2axang(obj.TargetTransform(1:3,1:3) * T(1:3,1:3).');
            angle = abs(aa(4));
            distance = norm(obj.TargetTransform(1:3,4) - T(1:3,4));
            r = [obj.Weights(1) * max(angle - obj.OrientationTolerance, 0); ...
                 obj.Weights(2) * max(distance - obj.PositionTolerance, 0)];
        end
    end
end
