classdef constraintCartesianBounds
%CONSTRAINTCARTESIANBOUNDS Contrainte de boîte sur la position d'un corps.
%   C = CONSTRAINTCARTESIANBOUNDS(CORPS) confine l'origine de CORPS dans
%   une boîte, exprimée dans le repère TargetTransform.
%
%   Propriétés :
%      EndEffector      - le corps contraint
%      ReferenceBody    - le repère de référence
%      TargetTransform  - le repère où la boîte est décrite
%      Bounds           - 3 lignes de [minimum maximum]
%      Weights          - le poids de la contrainte
%
%   Une boîte contraint sans fixer : c'est ce qu'il faut pour dire « reste
%   au-dessus de la table » ou « ne dépasse pas cette limite », qui sont
%   les contraintes réelles d'une cellule de travail.
%
%   Exemple :
%      c = constraintCartesianBounds('outil');
%      c.Bounds = [-inf inf; -inf inf; 0.1 inf];   % rester en hauteur
%
%   Voir aussi CONSTRAINTPOSITIONTARGET, GENERALIZEDINVERSEKINEMATICS.
    properties
        EndEffector = ''
        ReferenceBody = ''
        TargetTransform = eye(4)
        Bounds = [-inf inf; -inf inf; -inf inf]
        Weights = 1
    end
    methods
        function obj = constraintCartesianBounds(corps, varargin)
            if nargin > 0
                obj.EndEffector = char(corps);
            end
            for k = 1:2:numel(varargin)
                obj.(varargin{k}) = varargin{k+1};
            end
        end
        function r = matlibre_residu(obj, robot, config)
            T = matlibre_rob_poseRelative(robot, config, obj.EndEffector, obj.ReferenceBody);
            p = obj.TargetTransform \ [T(1:3,4); 1];
            r = zeros(3, 1);
            for k = 1:3
                r(k) = obj.Weights * (max(obj.Bounds(k,1) - p(k), 0) + ...
                                      max(p(k) - obj.Bounds(k,2), 0));
            end
        end
    end
end
