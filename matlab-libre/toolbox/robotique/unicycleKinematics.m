classdef unicycleKinematics < handle
%UNICYCLEKINEMATICS Modèle cinématique de l'unicycle.
%   MODELE = UNICYCLEKINEMATICS() décrit un mobile commandé par sa vitesse
%   d'avance et sa vitesse de rotation. C'est le modèle le plus simple
%   d'un robot à roues, et celui auquel les autres se ramènent.
%
%   Propriétés :
%      WheelRadius    - le rayon de roue, pour la commande en tours/s
%      WheelSpeedRange - [minimum maximum] de la vitesse de roue
%      VehicleInputs  - 'VehicleSpeedHeadingRate' ou 'WheelSpeedHeadingRate'
%
%   L'état est [X Y THETA]. DERIVATIVE(MODELE,ETAT,COMMANDE) rend sa
%   dérivée, qu'on intègre ensuite comme on veut :
%
%      dx = V cos(THETA), dy = V sin(THETA), dtheta = OMEGA
%
%   Exemple :
%      modele = unicycleKinematics();
%      derivative(modele, [0 0 0], [1 0.5])     % [1 0 0.5]
%
%   Voir aussi DIFFERENTIALDRIVEKINEMATICS, BICYCLEKINEMATICS,
%   ACKERMANNKINEMATICS, CONTROLLERPUREPURSUIT.
    properties
        WheelRadius = 0.05
        WheelSpeedRange = [-inf inf]
        VehicleInputs = 'VehicleSpeedHeadingRate'
    end
    methods
        function obj = unicycleKinematics(varargin)
            for k = 1:2:numel(varargin)
                obj.(varargin{k}) = varargin{k+1};
            end
        end
        function d = derivative(obj, etat, commande)
        %DERIVATIVE Dérivée de l'état sous une commande donnée.
            etat = double(etat(:)).';
            commande = double(commande(:)).';
            if strcmpi(obj.VehicleInputs, 'WheelSpeedHeadingRate')
                v = commande(1) * obj.WheelRadius;
            else
                v = commande(1);
            end
            omega = commande(2);
            theta = etat(3);
            d = [v * cos(theta); v * sin(theta); omega];
        end
    end
end
