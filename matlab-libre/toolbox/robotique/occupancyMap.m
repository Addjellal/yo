classdef occupancyMap < handle
%OCCUPANCYMAP Carte d'occupation probabiliste.
%   MAP = OCCUPANCYMAP(LARGEUR,HAUTEUR,RESOLUTION) crée une carte où
%   chaque cellule porte une probabilité d'être occupée, et non un simple
%   oui ou non. Les cellules valent 0.5 tant que rien ne les a
%   renseignées : ni libres, ni occupées, inconnues.
%
%   Propriétés :
%      GridSize, Resolution, XWorldLimits, YWorldLimits
%      GridLocationInWorld  - le coin inférieur gauche, dans le monde
%      DefaultValue         - la probabilité des cellules jamais vues
%      OccupiedThreshold    - au-dessus, la cellule compte pour occupée
%      FreeThreshold        - en dessous, elle compte pour libre
%      ProbabilitySaturation - [bas haut] où les probabilités se bloquent
%
%   Ce qu'on lui demande :
%      SETOCCUPANCY, GETOCCUPANCY - écrire et lire une probabilité
%      UPDATEOCCUPANCY            - accumuler une observation
%      CHECKOCCUPANCY             - trancher : 0 libre, 1 occupée, -1 inconnue
%      INSERTRAY                  - intégrer tout un relevé télémétrique
%      RAYCAST, INFLATE, OCCUPANCYMATRIX, WORLD2GRID, GRID2WORLD
%
%   Les mises à jour se font en logarithme de rapport de cotes : dans
%   cette échelle, accumuler des observations indépendantes revient à les
%   additionner, ce qui est à la fois exact et sans risque de saturation
%   numérique aux extrêmes.
%
%   La saturation, elle, est voulue : borner les probabilités à [0.001,
%   0.999] permet à la carte de se corriger quand le monde change, là où
%   une certitude absolue serait définitive.
%
%   Exemple :
%      map = occupancyMap(10, 10, 2);
%      updateOccupancy(map, [5 5], true);      % une observation d'obstacle
%      getOccupancy(map, [5 5])                % au-dessus de 0.5
%      insertRay(map, [1 1 0], 3, 0, 5);       % un rayon complet
%
%   Voir aussi BINARYOCCUPANCYMAP, CONTROLLERVFH.
    properties
        GridLocationInWorld = [0 0]
        DefaultValue = 0.5
        OccupiedThreshold = 0.65
        FreeThreshold = 0.2
        ProbabilitySaturation = [0.001 0.999]
    end
    properties (SetAccess = private)
        Resolution = 1
        cotes = zeros(0, 0)     % logarithme du rapport de cotes
    end
    methods
        function obj = occupancyMap(a, b, resolution)
            if nargin == 0
                a = 10; b = 10;
            end
            if nargin >= 3
                obj.Resolution = resolution;
            end
            if nargin == 1 || (nargin == 2 && ~isscalar(a))
                p = double(a);
                if nargin == 2
                    obj.Resolution = b;
                end
                obj.cotes = log(p ./ max(1 - p, eps));
            else
                lignes = round(b * obj.Resolution);
                colonnes = round(a * obj.Resolution);
                obj.cotes = zeros(lignes, colonnes);
            end
        end

        function s = get.GridSize(obj)
            s = size(obj.cotes);
        end
        function l = get.XWorldLimits(obj)
            l = obj.GridLocationInWorld(1) + [0, size(obj.cotes, 2) / obj.Resolution];
        end
        function l = get.YWorldLimits(obj)
            l = obj.GridLocationInWorld(2) + [0, size(obj.cotes, 1) / obj.Resolution];
        end

        function ij = world2grid(obj, xy)
        %WORLD2GRID Indices de cellule d'un point du monde.
            xy = double(xy);
            colonne = floor((xy(:,1) - obj.GridLocationInWorld(1)) * obj.Resolution) + 1;
            ligne = size(obj.cotes, 1) ...
                    - floor((xy(:,2) - obj.GridLocationInWorld(2)) * obj.Resolution);
            ij = [ligne, colonne];
        end

        function xy = grid2world(obj, ij)
        %GRID2WORLD Centre de la cellule, en coordonnées du monde.
            ij = double(ij);
            x = obj.GridLocationInWorld(1) + (ij(:,2) - 0.5) / obj.Resolution;
            y = obj.GridLocationInWorld(2) ...
                + (size(obj.cotes, 1) - ij(:,1) + 0.5) / obj.Resolution;
            xy = [x, y];
        end

        function setOccupancy(obj, position, valeur, repere)
        %SETOCCUPANCY Impose la probabilité d'une ou plusieurs cellules.
            if nargin < 4, repere = 'world'; end
            ij = obj.matlibre_indices(position, repere);
            if isscalar(valeur)
                valeur = repmat(valeur, size(ij, 1), 1);
            end
            for k = 1:size(ij, 1)
                if obj.matlibre_dedans(ij(k, :))
                    p = min(max(valeur(k), obj.ProbabilitySaturation(1)), ...
                            obj.ProbabilitySaturation(2));
                    obj.cotes(ij(k,1), ij(k,2)) = log(p / (1 - p));
                end
            end
        end

        function v = getOccupancy(obj, position, repere)
        %GETOCCUPANCY Probabilité d'occupation d'une ou plusieurs cellules.
            if nargin < 3, repere = 'world'; end
            ij = obj.matlibre_indices(position, repere);
            v = zeros(size(ij, 1), 1);
            for k = 1:size(ij, 1)
                if obj.matlibre_dedans(ij(k, :))
                    c = obj.cotes(ij(k,1), ij(k,2));
                    v(k) = 1 / (1 + exp(-c));
                else
                    v(k) = obj.DefaultValue;
                end
            end
        end

        function updateOccupancy(obj, position, observation, repere)
        %UPDATEOCCUPANCY Accumule une observation sur une cellule.
        %   Une observation vraie pousse vers l'occupation, une fausse
        %   vers le vide. Un nombre entre zéro et un s'ajoute directement
        %   en logarithme de rapport de cotes.
            if nargin < 4, repere = 'world'; end
            if nargin < 3, observation = true; end
            ij = obj.matlibre_indices(position, repere);
            if islogical(observation) || isscalar(observation)
                observation = repmat(observation, size(ij, 1), 1);
            end
            bas = log(obj.ProbabilitySaturation(1) / (1 - obj.ProbabilitySaturation(1)));
            haut = log(obj.ProbabilitySaturation(2) / (1 - obj.ProbabilitySaturation(2)));
            for k = 1:size(ij, 1)
                if ~obj.matlibre_dedans(ij(k, :))
                    continue
                end
                o = observation(k);
                if islogical(o)
                    if o
                        increment = log(0.7 / 0.3);
                    else
                        increment = log(0.4 / 0.6);
                    end
                else
                    p = min(max(double(o), obj.ProbabilitySaturation(1)), ...
                            obj.ProbabilitySaturation(2));
                    increment = log(p / (1 - p));
                end
                obj.cotes(ij(k,1), ij(k,2)) = ...
                    min(max(obj.cotes(ij(k,1), ij(k,2)) + increment, bas), haut);
            end
        end

        function v = checkOccupancy(obj, position, repere)
        %CHECKOCCUPANCY Tranche : 0 libre, 1 occupée, -1 inconnue.
            if nargin < 3, repere = 'world'; end
            p = obj.getOccupancy(position, repere);
            v = -ones(size(p));
            v(p >= obj.OccupiedThreshold) = 1;
            v(p <= obj.FreeThreshold) = 0;
        end

        function m = occupancyMatrix(obj)
        %OCCUPANCYMATRIX La grille entière, en probabilités.
            m = 1 ./ (1 + exp(-obj.cotes));
        end

        function [cellules, arrivee] = raycast(obj, depart, arriveeOuPortee, angle)
        %RAYCAST Cellules traversées par un rayon.
            if nargin >= 4
                cap = depart(3) + angle;
                fin = depart(1:2) + arriveeOuPortee * [cos(cap), sin(cap)];
                debut = depart(1:2);
            else
                debut = depart(1:2);
                fin = arriveeOuPortee(1:2);
            end
            cellules = matlibre_rob_bresenham(obj.world2grid(debut), obj.world2grid(fin));
            arrivee = obj.world2grid(fin);
        end

        function insertRay(obj, pose, distances, angles, portee)
        %INSERTRAY Intègre un relevé télémétrique complet.
        %   Chaque rayon libère les cellules qu'il traverse et occupe
        %   celle où il s'arrête — sauf s'il atteint la portée maximale,
        %   auquel cas rien ne l'a arrêté et il ne faut rien y marquer.
            pose = double(pose(:)).';
            distances = double(distances(:)).';
            angles = double(angles(:)).';
            if nargin < 5
                portee = inf;
            end
            for k = 1:numel(distances)
                d = distances(k);
                touche = isfinite(d) && d < portee;
                d = min(d, portee);
                if ~isfinite(d)
                    continue
                end
                cellules = obj.raycast(pose, d, angles(k));
                if isempty(cellules)
                    continue
                end
                if touche
                    obj.updateOccupancy(cellules(1:end-1, :), false, 'grid');
                    obj.updateOccupancy(cellules(end, :), true, 'grid');
                else
                    obj.updateOccupancy(cellules, false, 'grid');
                end
            end
        end

        function inflate(obj, rayon, repere)
        %INFLATE Épaissit les zones occupées du rayon donné.
            if nargin < 3, repere = 'world'; end
            if strcmpi(repere, 'grid')
                cellules = round(rayon);
            else
                cellules = round(rayon * obj.Resolution);
            end
            if cellules <= 0
                return
            end
            [lignes, colonnes] = size(obj.cotes);
            p = obj.occupancyMatrix();
            occupees = p >= obj.OccupiedThreshold;
            [li, co] = find(occupees);
            nouvelle = obj.cotes;
            seuil = log(obj.OccupiedThreshold / (1 - obj.OccupiedThreshold));
            for k = 1:numel(li)
                for a = -cellules:cellules
                    for b = -cellules:cellules
                        if a^2 + b^2 > cellules^2
                            continue
                        end
                        i = li(k) + a;
                        j = co(k) + b;
                        if i >= 1 && i <= lignes && j >= 1 && j <= colonnes
                            nouvelle(i, j) = max(nouvelle(i, j), seuil);
                        end
                    end
                end
            end
            obj.cotes = nouvelle;
        end

        function move(obj, position)
        %MOVE Déplace le coin inférieur gauche de la carte.
            obj.GridLocationInWorld = double(position(:)).';
        end

        function autre = copy(obj)
        %COPY Copie indépendante de la carte.
            autre = occupancyMap(obj.occupancyMatrix(), obj.Resolution);
            autre.GridLocationInWorld = obj.GridLocationInWorld;
            autre.OccupiedThreshold = obj.OccupiedThreshold;
            autre.FreeThreshold = obj.FreeThreshold;
            autre.ProbabilitySaturation = obj.ProbabilitySaturation;
        end

        function show(obj)
        %SHOW Trace la carte, l'origine en bas à gauche.
            imagesc(obj.XWorldLimits, obj.YWorldLimits, flipud(obj.occupancyMatrix()));
            axis xy
            axis equal
            colormap(flipud(gray));
            xlabel('X [m]');
            ylabel('Y [m]');
        end
    end
    properties (Dependent)
        GridSize
        XWorldLimits
        YWorldLimits
    end
    methods (Access = private)
        function ij = matlibre_indices(obj, position, repere)
            position = double(position);
            if size(position, 2) == 1
                position = position(:).';
            end
            if strcmpi(repere, 'grid')
                ij = round(position);
            else
                ij = obj.world2grid(position);
            end
        end
        function dedans = matlibre_dedans(obj, ij)
            dedans = ij(1) >= 1 && ij(1) <= size(obj.cotes, 1) && ...
                     ij(2) >= 1 && ij(2) <= size(obj.cotes, 2);
        end
    end
end
