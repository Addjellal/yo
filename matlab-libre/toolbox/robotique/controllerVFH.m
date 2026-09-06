classdef controllerVFH < handle
%CONTROLLERVFH Évitement d'obstacles par histogramme de champ de vecteurs.
%   VFH = CONTROLLERVFH() construit le régulateur ; on l'appelle avec un
%   relevé télémétrique et la direction voulue :
%
%      CAP = VFH(DISTANCES,ANGLES,DIRECTIONVOULUE)
%
%   Propriétés :
%      NumAngularSectors       - le nombre de secteurs de l'histogramme
%      DistanceLimits          - [minimum maximum] des distances prises
%      RobotRadius             - le rayon du robot
%      SafetyDistance          - la marge ajoutée au rayon
%      MinTurningRadius        - le rayon de virage minimal
%      TargetDirectionWeight   - le poids de la direction voulue
%      CurrentDirectionWeight  - le poids du cap actuel
%      PreviousDirectionWeight - le poids du cap précédent
%      HistogramThresholds     - [bas haut] de l'hystérésis
%
%   Le principe : découper le tour du robot en secteurs, mesurer dans
%   chacun la densité d'obstacles, retenir les vallées assez larges pour
%   passer, et y choisir la direction qui coûte le moins — en pesant
%   l'écart au but, l'écart au cap actuel et l'écart au cap précédent.
%   Ce dernier terme est ce qui empêche le robot d'hésiter entre deux
%   passages équivalents.
%
%   Rend NaN quand aucune direction ne convient : c'est un renseignement,
%   non un échec — il faut alors reculer ou changer de but.
%
%   Exemple :
%      vfh = controllerVFH();
%      distances = 3 * ones(1, 181);
%      distances(80:100) = 0.4;              % un obstacle droit devant
%      cap = vfh(distances, linspace(-pi/2, pi/2, 181), 0);
%
%   Voir aussi CONTROLLERPUREPURSUIT, BINARYOCCUPANCYMAP.
    properties
        NumAngularSectors = 180
        DistanceLimits = [0.05 2]
        RobotRadius = 0.1
        SafetyDistance = 0.1
        MinTurningRadius = 0.1
        TargetDirectionWeight = 5
        CurrentDirectionWeight = 2
        PreviousDirectionWeight = 2
        HistogramThresholds = [3 10]
    end
    properties (Access = private)
        capPrecedent = 0
    end
    methods
        function obj = controllerVFH(varargin)
            for k = 1:2:numel(varargin)
                obj.(varargin{k}) = varargin{k+1};
            end
        end

        function varargout = subsref(obj, s)
            if strcmp(s(1).type, '()')
                varargout{1} = diriger(obj, s(1).subs{:});
                return
            end
            [varargout{1:nargout}] = builtin('subsref', obj, s);
        end

        function cap = diriger(obj, distances, angles, direction)
        %DIRIGER Cap à prendre, ou NaN si rien ne passe.
            if nargin < 4
                direction = 0;
            end
            distances = double(distances(:)).';
            angles = double(angles(:)).';
            valides = isfinite(distances) & distances >= obj.DistanceLimits(1);
            % Secteurs réguliers couvrant le champ du télémètre.
            bords = linspace(min(angles), max(angles), obj.NumAngularSectors + 1);
            centres = (bords(1:end-1) + bords(2:end)) / 2;
            densite = zeros(1, obj.NumAngularSectors);
            for k = 1:obj.NumAngularSectors
                dans = valides & angles >= bords(k) & angles <= bords(k+1);
                if ~any(dans)
                    continue
                end
                d = min(distances(dans), obj.DistanceLimits(2));
                % Un obstacle proche pèse plus qu'un obstacle lointain :
                % c'est ce que la magnitude de l'histogramme exprime.
                densite(k) = max((obj.DistanceLimits(2) - d) .^ 2);
            end
            marge = obj.RobotRadius + obj.SafetyDistance;
            seuilBas = obj.HistogramThresholds(1) * marge;
            seuilHaut = obj.HistogramThresholds(2) * marge;
            libre = densite < seuilBas;
            libre(densite > seuilHaut) = false;
            if ~any(libre)
                cap = NaN;
                return
            end
            % Chaque secteur libre est un candidat ; on retient celui dont
            % le coût est le plus faible.
            cout = inf(1, obj.NumAngularSectors);
            for k = find(libre)
                cout(k) = obj.TargetDirectionWeight * abs(angdiff(centres(k), direction)) ...
                        + obj.CurrentDirectionWeight * abs(centres(k)) ...
                        + obj.PreviousDirectionWeight * abs(angdiff(centres(k), obj.capPrecedent));
            end
            [~, meilleur] = min(cout);
            cap = centres(meilleur);
            obj.capPrecedent = cap;
        end
    end
end
