classdef binaryOccupancyMap < handle
%BINARYOCCUPANCYMAP Carte d'occupation binaire, en coordonnées du monde.
%   MAP = BINARYOCCUPANCYMAP(LARGEUR,HAUTEUR,RESOLUTION) crée une carte de
%   LARGEUR sur HAUTEUR mètres, à RESOLUTION cellules par mètre. La
%   résolution vaut un par défaut.
%   MAP = BINARYOCCUPANCYMAP(M) reprend une matrice logique déjà faite.
%
%   Propriétés :
%      GridSize             - [lignes colonnes]
%      Resolution           - cellules par mètre
%      XWorldLimits         - [minimum maximum] en x
%      YWorldLimits         - [minimum maximum] en y
%      GridLocationInWorld  - le coin inférieur gauche, dans le monde
%      DefaultValue         - la valeur des cellules jamais renseignées
%
%   Ce qu'on lui demande :
%      SETOCCUPANCY, GETOCCUPANCY  - écrire et lire une cellule
%      CHECKOCCUPANCY              - lire en signalant le hors carte
%      WORLD2GRID, GRID2WORLD      - passer d'un repère à l'autre
%      OCCUPANCYMATRIX             - la matrice entière
%      INFLATE                     - épaissir les obstacles
%      RAYCAST                     - les cellules traversées par un rayon
%      MOVE                        - déplacer la carte dans le monde
%
%   La ligne 1 de la grille est le haut de la carte, donc la plus grande
%   ordonnée : c'est la convention des images, et celle de MATLAB.
%
%   INFLATE épaissit les obstacles du rayon du robot, ce qui permet
%   ensuite de planifier en traitant le robot comme un point — c'est tout
%   l'intérêt de l'opération.
%
%   Exemple :
%      map = binaryOccupancyMap(10, 10, 2);
%      setOccupancy(map, [5 5], 1);
%      getOccupancy(map, [5 5])        % 1
%      inflate(map, 0.5);
%      getOccupancy(map, [5.4 5])      % 1 : l'obstacle a grossi
%
%   Voir aussi OCCUPANCYMAP, CONTROLLERVFH.
    properties
        GridLocationInWorld = [0 0]
        DefaultValue = 0
    end
    properties (SetAccess = protected)
        Resolution = 1
        grille = false(0, 0)
    end
    methods
        function obj = binaryOccupancyMap(a, b, resolution)
            if nargin == 0
                a = 10; b = 10;
            end
            if nargin >= 3
                obj.Resolution = resolution;
            elseif nargin == 2 && isscalar(a) && isscalar(b)
                obj.Resolution = 1;
            end
            if nargin == 1 || (nargin == 2 && ~isscalar(a))
                m = logical(a);
                if nargin == 2
                    obj.Resolution = b;
                end
                obj.grille = m;
            else
                lignes = round(b * obj.Resolution);
                colonnes = round(a * obj.Resolution);
                obj.grille = false(lignes, colonnes);
            end
        end

        function s = get.GridSize(obj)
            s = size(obj.grille);
        end
        function l = get.XWorldLimits(obj)
            l = obj.GridLocationInWorld(1) + [0, size(obj.grille, 2) / obj.Resolution];
        end
        function l = get.YWorldLimits(obj)
            l = obj.GridLocationInWorld(2) + [0, size(obj.grille, 1) / obj.Resolution];
        end

        function ij = world2grid(obj, xy)
        %WORLD2GRID Indices de cellule d'un point du monde.
            xy = double(xy);
            colonne = floor((xy(:,1) - obj.GridLocationInWorld(1)) * obj.Resolution) + 1;
            ligne = size(obj.grille, 1) ...
                    - floor((xy(:,2) - obj.GridLocationInWorld(2)) * obj.Resolution);
            ij = [ligne, colonne];
        end

        function xy = grid2world(obj, ij)
        %GRID2WORLD Centre de la cellule, en coordonnées du monde.
            ij = double(ij);
            x = obj.GridLocationInWorld(1) + (ij(:,2) - 0.5) / obj.Resolution;
            y = obj.GridLocationInWorld(2) ...
                + (size(obj.grille, 1) - ij(:,1) + 0.5) / obj.Resolution;
            xy = [x, y];
        end

        function setOccupancy(obj, position, valeur, repere)
        %SETOCCUPANCY Écrit l'occupation d'une ou plusieurs cellules.
            if nargin < 4, repere = 'world'; end
            ij = obj.matlibre_indices(position, repere);
            if isscalar(valeur)
                valeur = repmat(valeur, size(ij, 1), 1);
            end
            for k = 1:size(ij, 1)
                if obj.matlibre_dedans(ij(k, :))
                    obj.grille(ij(k,1), ij(k,2)) = logical(valeur(k));
                end
            end
        end

        function v = getOccupancy(obj, position, repere)
        %GETOCCUPANCY Lit l'occupation d'une ou plusieurs cellules.
            if nargin < 3, repere = 'world'; end
            ij = obj.matlibre_indices(position, repere);
            v = zeros(size(ij, 1), 1);
            for k = 1:size(ij, 1)
                if obj.matlibre_dedans(ij(k, :))
                    v(k) = double(obj.grille(ij(k,1), ij(k,2)));
                else
                    v(k) = obj.DefaultValue;
                end
            end
        end

        function v = checkOccupancy(obj, position, repere)
        %CHECKOCCUPANCY Comme GETOCCUPANCY, mais -1 hors de la carte.
            if nargin < 3, repere = 'world'; end
            ij = obj.matlibre_indices(position, repere);
            v = zeros(size(ij, 1), 1);
            for k = 1:size(ij, 1)
                if obj.matlibre_dedans(ij(k, :))
                    v(k) = double(obj.grille(ij(k,1), ij(k,2)));
                else
                    v(k) = -1;
                end
            end
        end

        function m = occupancyMatrix(obj)
        %OCCUPANCYMATRIX La grille entière, une cellule par élément.
            m = obj.grille;
        end

        function inflate(obj, rayon, repere)
        %INFLATE Épaissit les obstacles du rayon donné.
            if nargin < 3, repere = 'world'; end
            if strcmpi(repere, 'grid')
                cellules = round(rayon);
            else
                cellules = round(rayon * obj.Resolution);
            end
            if cellules <= 0
                return
            end
            [lignes, colonnes] = size(obj.grille);
            % Élément structurant en disque : c'est le rayon du robot,
            % pas un carré.
            [dx, dy] = meshgrid(-cellules:cellules, -cellules:cellules);
            masque = (dx .^ 2 + dy .^ 2) <= cellules ^ 2;
            nouvelle = obj.grille;
            [ligneObstacle, colonneObstacle] = find(obj.grille);
            for k = 1:numel(ligneObstacle)
                for a = -cellules:cellules
                    for b = -cellules:cellules
                        if ~masque(a + cellules + 1, b + cellules + 1)
                            continue
                        end
                        i = ligneObstacle(k) + a;
                        j = colonneObstacle(k) + b;
                        if i >= 1 && i <= lignes && j >= 1 && j <= colonnes
                            nouvelle(i, j) = true;
                        end
                    end
                end
            end
            obj.grille = nouvelle;
        end

        function move(obj, position)
        %MOVE Déplace le coin inférieur gauche de la carte.
            obj.GridLocationInWorld = double(position(:)).';
        end

        function [cellules, arrivee] = raycast(obj, depart, arriveeOuPortee, angle)
        %RAYCAST Cellules traversées par un rayon, par l'algorithme de Bresenham.
        %   [C,FIN] = RAYCAST(MAP,[X1 Y1],[X2 Y2]) suit le segment.
        %   [C,FIN] = RAYCAST(MAP,POSE,PORTEE,ANGLE) suit un rayon depuis
        %   une pose [X Y THETA].
            if nargin >= 4
                cap = depart(3) + angle;
                fin = depart(1:2) + arriveeOuPortee * [cos(cap), sin(cap)];
                debut = depart(1:2);
            else
                debut = depart(1:2);
                fin = arriveeOuPortee(1:2);
            end
            a = obj.world2grid(debut);
            b = obj.world2grid(fin);
            cellules = matlibre_rob_bresenham(a, b);
            arrivee = b;
        end

        function autre = copy(obj)
        %COPY Copie indépendante de la carte.
            autre = binaryOccupancyMap(obj.grille, obj.Resolution);
            autre.GridLocationInWorld = obj.GridLocationInWorld;
            autre.DefaultValue = obj.DefaultValue;
        end

        function show(obj)
        %SHOW Trace la carte, l'origine en bas à gauche.
            imagesc(obj.XWorldLimits, obj.YWorldLimits, flipud(double(obj.grille)));
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
    methods (Access = protected)
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
            dedans = ij(1) >= 1 && ij(1) <= size(obj.grille, 1) && ...
                     ij(2) >= 1 && ij(2) <= size(obj.grille, 2);
        end
    end
end
