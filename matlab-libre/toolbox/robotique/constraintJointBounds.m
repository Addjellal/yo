classdef constraintJointBounds
%CONSTRAINTJOINTBOUNDS Contrainte de butée sur les liaisons.
%   C = CONSTRAINTJOINTBOUNDS(ROBOT) reprend les butées déclarées par
%   chaque liaison de ROBOT ; on peut ensuite les resserrer.
%
%   Propriétés :
%      Bounds   - une ligne [minimum maximum] par liaison mobile
%      Weights  - un poids par liaison
%
%   Resserrer les butées d'une seule liaison est la façon la plus simple
%   de choisir entre deux solutions de cinématique inverse : coude haut ou
%   coude bas ne diffèrent que par le signe d'un angle.
%
%   Exemple :
%      urdf = ['<?xml version="1.0"?><robot name="deux">' ...
%              '<link name="base_link"/><link name="l1"/>' ...
%              '<link name="effecteur"/>' ...
%              '<joint name="j1" type="revolute"><parent link="base_link"/>' ...
%              '<child link="l1"/><origin xyz="0 0 0"/><axis xyz="0 0 1"/>' ...
%              '<limit lower="-3.14" upper="3.14"/></joint>' ...
%              '<joint name="j2" type="revolute"><parent link="l1"/>' ...
%              '<child link="effecteur"/><origin xyz="0.4 0 0"/><axis xyz="0 0 1"/>' ...
%              '<limit lower="-3.14" upper="3.14"/></joint></robot>'];
%      robot = importrobot(urdf, 'DataFormat', 'row');
%      c = constraintJointBounds(robot);
%      c.Bounds(2, :) = [0 pi];        % force le coude d'un cote
%
%   Voir aussi GENERALIZEDINVERSEKINEMATICS, RIGIDBODYJOINT.
    properties
        Bounds = zeros(0, 2)
        Weights = zeros(1, 0)
    end
    methods
        function obj = constraintJointBounds(robot, varargin)
            if nargin > 0 && ~isempty(robot)
                bas = [];
                haut = [];
                for k = 1:robot.NumBodies
                    j = robot.Bodies{k}.Joint;
                    if matlibre_ddl(j) > 0
                        bas(end + 1) = j.PositionLimits(1);    %#ok<AGROW>
                        haut(end + 1) = j.PositionLimits(2);   %#ok<AGROW>
                    end
                end
                obj.Bounds = [bas(:), haut(:)];
                obj.Weights = ones(1, numel(bas));
            end
            for k = 1:2:numel(varargin)
                obj.(varargin{k}) = varargin{k+1};
            end
        end
        function r = matlibre_residu(obj, robot, config)
            q = matlibre_deshabiller(robot, config);
            r = zeros(numel(q), 1);
            for k = 1:min(numel(q), size(obj.Bounds, 1))
                poids = obj.Weights(min(k, numel(obj.Weights)));
                r(k) = poids * (max(obj.Bounds(k,1) - q(k), 0) + ...
                                max(q(k) - obj.Bounds(k,2), 0));
            end
        end
    end
end
