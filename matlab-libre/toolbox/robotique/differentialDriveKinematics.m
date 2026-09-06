classdef differentialDriveKinematics < handle
%DIFFERENTIALDRIVEKINEMATICS Modèle d'un mobile à entraînement différentiel.
%   MODELE = DIFFERENTIALDRIVEKINEMATICS() décrit un robot à deux roues
%   motrices indépendantes. C'est le modèle des robots d'intérieur les
%   plus répandus : tourner sur place ne leur coûte rien, faire des
%   trajectoires courbes non plus.
%
%   Propriétés :
%      WheelRadius     - le rayon des roues
%      TrackWidth      - l'écartement entre les deux roues
%      WheelSpeedRange - [minimum maximum] de la vitesse de roue
%      VehicleInputs   - 'WheelSpeeds' ou 'VehicleSpeedHeadingRate'
%
%   L'état est [X Y THETA]. Avec les vitesses de roue WL et WR :
%
%      V = R (WR + WL) / 2,  OMEGA = R (WR - WL) / TrackWidth
%
%   Les deux roues à la même vitesse donnent une ligne droite ; en sens
%   contraire, une rotation sur place. Tout le reste est entre les deux.
%
%   Exemple :
%      modele = differentialDriveKinematics('WheelRadius', 0.1, ...
%                                           'TrackWidth', 0.5);
%      derivative(modele, [0 0 0], [1 1])       % tout droit
%      derivative(modele, [0 0 0], [-1 1])      % sur place
%
%   Voir aussi UNICYCLEKINEMATICS, BICYCLEKINEMATICS, ACKERMANNKINEMATICS.
    properties
        WheelRadius = 0.05
        TrackWidth = 0.2
        WheelSpeedRange = [-inf inf]
        VehicleInputs = 'WheelSpeeds'
    end
    methods
        function obj = differentialDriveKinematics(varargin)
            for k = 1:2:numel(varargin)
                obj.(varargin{k}) = varargin{k+1};
            end
        end
        function d = derivative(obj, etat, commande)
        %DERIVATIVE Dérivée de l'état sous une commande donnée.
            etat = double(etat(:)).';
            commande = double(commande(:)).';
            if strcmpi(obj.VehicleInputs, 'VehicleSpeedHeadingRate')
                v = commande(1);
                omega = commande(2);
            else
                w = min(max(commande(1:2), obj.WheelSpeedRange(1)), ...
                        obj.WheelSpeedRange(2));
                v = obj.WheelRadius * (w(2) + w(1)) / 2;
                omega = obj.WheelRadius * (w(2) - w(1)) / obj.TrackWidth;
            end
            theta = etat(3);
            d = [v * cos(theta); v * sin(theta); omega];
        end
    end
end
