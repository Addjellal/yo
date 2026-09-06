classdef constraintDistanceBounds
%CONSTRAINTDISTANCEBOUNDS Contrainte de distance entre deux corps.
%   C = CONSTRAINTDISTANCEBOUNDS(CORPS) demande que la distance entre
%   l'origine de CORPS et celle de ReferenceBody reste entre les Bounds.
%
%   Propriétés :
%      EndEffector    - le corps contraint
%      ReferenceBody  - l'autre corps, la base par défaut
%      Bounds         - [minimum maximum], en mètres
%      Weights        - le poids de la contrainte
%
%   Une distance minimale tient à l'écart d'un obstacle ; une distance
%   maximale garde l'outil à portée. Les deux ensemble décrivent une
%   coquille sphérique, sans rien dire de la direction.
%
%   Exemple :
%      c = constraintDistanceBounds('outil');
%      c.Bounds = [0.2 0.8];
%
%   Voir aussi CONSTRAINTCARTESIANBOUNDS, GENERALIZEDINVERSEKINEMATICS.
    properties
        EndEffector = ''
        ReferenceBody = ''
        Bounds = [0 inf]
        Weights = 1
    end
    methods
        function obj = constraintDistanceBounds(corps, varargin)
            if nargin > 0
                obj.EndEffector = char(corps);
            end
            for k = 1:2:numel(varargin)
                obj.(varargin{k}) = varargin{k+1};
            end
        end
        function r = matlibre_residu(obj, robot, config)
            T = matlibre_rob_poseRelative(robot, config, obj.EndEffector, obj.ReferenceBody);
            d = norm(T(1:3, 4));
            r = obj.Weights * (max(obj.Bounds(1) - d, 0) + max(d - obj.Bounds(2), 0));
        end
    end
end
