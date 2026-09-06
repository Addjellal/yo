classdef controllerPurePursuit < handle
%CONTROLLERPUREPURSUIT Suivi de chemin par poursuite pure.
%   CTRL = CONTROLLERPUREPURSUIT() construit le régulateur ; on lui donne
%   ensuite les points de passage, puis on l'appelle avec la pose :
%
%      [V,OMEGA] = CTRL([X Y THETA])
%
%   Propriétés :
%      Waypoints              - les points de passage, en lignes
%      LookaheadDistance      - la distance de visée
%      DesiredLinearVelocity  - la vitesse d'avance voulue
%      MaxAngularVelocity     - la vitesse de rotation maximale
%
%   [V,OMEGA,POINT] = CTRL(POSE) rend aussi le point visé.
%
%   Le régulateur vise un point du chemin situé à LookaheadDistance devant
%   lui et décrit l'arc de cercle qui y mène. La distance de visée est le
%   seul réglage : courte, le suivi oscille ; longue, il coupe les
%   virages.
%
%   Le point visé se cherche à partir du point le plus proche, jamais
%   depuis le début du chemin : sans cela, le régulateur finirait par
%   viser le départ, derrière lui.
%
%   Exemple :
%      ctrl = controllerPurePursuit();
%      ctrl.Waypoints = [0 0; 1 0; 2 1];
%      ctrl.LookaheadDistance = 0.5;
%      [v, w] = ctrl([0 0 0]);
%
%   Voir aussi PUREPURSUIT, CONTROLLERVFH, DIFFERENTIALDRIVEKINEMATICS.
    properties
        Waypoints = zeros(0, 2)
        LookaheadDistance = 1.0
        DesiredLinearVelocity = 0.5
        MaxAngularVelocity = 1.0
    end
    methods
        function obj = controllerPurePursuit(varargin)
            for k = 1:2:numel(varargin)
                obj.(varargin{k}) = varargin{k+1};
            end
        end

        function varargout = subsref(obj, s)
            if strcmp(s(1).type, '()')
                [v, omega, point] = commander(obj, s(1).subs{:});
                varargout = {v, omega, point};
                varargout = varargout(1:max(nargout, 1));
                return
            end
            [varargout{1:nargout}] = builtin('subsref', obj, s);
        end

        function [v, omega, point] = commander(obj, pose)
        %COMMANDER Vitesses d'avance et de rotation pour cette pose.
            if isempty(obj.Waypoints)
                error('robotics:controllerPurePursuit:SansChemin', ...
                      'Le regulateur demande des Waypoints.');
            end
            pose = double(pose(:)).';
            [omegaBrut, indice] = purePursuit(pose, obj.Waypoints, ...
                                              obj.LookaheadDistance, ...
                                              obj.DesiredLinearVelocity);
            point = obj.Waypoints(indice, :);
            omega = min(max(omegaBrut, -obj.MaxAngularVelocity), ...
                        obj.MaxAngularVelocity);
            v = obj.DesiredLinearVelocity;
            % Arrivé au dernier point de passage, il n'y a plus rien à
            % suivre : le régulateur s'arrête plutôt que de tourner
            % indéfiniment autour de la fin du chemin.
            if norm(obj.Waypoints(end, :) - pose(1:2)) < obj.LookaheadDistance / 10
                v = 0;
                omega = 0;
            end
        end
    end
end
