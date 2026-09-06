classdef ackermannKinematics < handle
%ACKERMANNKINEMATICS Modèle d'Ackermann, le braquage devenant un état.
%   MODELE = ACKERMANNKINEMATICS() décrit un véhicule où le braquage
%   n'est plus une commande instantanée mais un état, commandé par sa
%   vitesse de variation. C'est plus réaliste que le modèle bicyclette :
%   une colonne de direction ne saute pas d'un angle à un autre.
%
%   Propriétés :
%      WheelBase        - l'empattement
%      MaxSteeringAngle - le braquage maximal, en radians
%
%   L'état est [X Y THETA PSI], la commande [V DPSI] :
%
%      dtheta = V tan(PSI) / WheelBase,  dpsi = DPSI
%
%   Exemple :
%      modele = ackermannKinematics('WheelBase', 2.7);
%      derivative(modele, [0 0 0 0], [10 0.2])
%
%   Voir aussi BICYCLEKINEMATICS, UNICYCLEKINEMATICS.
    properties
        WheelBase = 1
        MaxSteeringAngle = pi/4
    end
    methods
        function obj = ackermannKinematics(varargin)
            for k = 1:2:numel(varargin)
                obj.(varargin{k}) = varargin{k+1};
            end
        end
        function d = derivative(obj, etat, commande)
        %DERIVATIVE Dérivée de l'état sous une commande donnée.
            etat = double(etat(:)).';
            commande = double(commande(:)).';
            v = commande(1);
            theta = etat(3);
            psi = min(max(etat(4), -obj.MaxSteeringAngle), obj.MaxSteeringAngle);
            d = [v * cos(theta); v * sin(theta); ...
                 v * tan(psi) / obj.WheelBase; commande(2)];
        end
    end
end
