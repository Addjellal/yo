classdef bicycleKinematics < handle
%BICYCLEKINEMATICS Modèle bicyclette d'un véhicule à direction avant.
%   MODELE = BICYCLEKINEMATICS() décrit un véhicule dont la roue avant
%   braque et dont la roue arrière suit. C'est le modèle de toute voiture
%   à basse vitesse, et il diffère de l'unicycle sur un point décisif : il
%   ne peut pas tourner sur place.
%
%   Propriétés :
%      WheelBase        - l'empattement, entre les deux essieux
%      MaxSteeringAngle - le braquage maximal, en radians
%      VehicleInputs    - 'VehicleSpeedSteeringAngle' ou
%                         'VehicleSpeedHeadingRate'
%
%   L'état est [X Y THETA]. Avec la vitesse V et le braquage PSI :
%
%      dtheta = V tan(PSI) / WheelBase
%
%   Le rayon de virage vaut donc WheelBase / tan(PSI), indépendant de la
%   vitesse : c'est la formule d'Ackermann.
%
%   Exemple :
%      modele = bicycleKinematics('WheelBase', 2.7);
%      derivative(modele, [0 0 0], [10 pi/12])
%
%   Voir aussi ACKERMANNKINEMATICS, UNICYCLEKINEMATICS, BICYCLEMODEL.
    properties
        WheelBase = 1
        MaxSteeringAngle = pi/4
        VehicleInputs = 'VehicleSpeedSteeringAngle'
    end
    methods
        function obj = bicycleKinematics(varargin)
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
            if strcmpi(obj.VehicleInputs, 'VehicleSpeedHeadingRate')
                omega = commande(2);
            else
                psi = min(max(commande(2), -obj.MaxSteeringAngle), ...
                          obj.MaxSteeringAngle);
                omega = v * tan(psi) / obj.WheelBase;
            end
            d = [v * cos(theta); v * sin(theta); omega];
        end
    end
end
