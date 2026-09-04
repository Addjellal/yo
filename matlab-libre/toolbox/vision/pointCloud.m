classdef pointCloud
%POINTCLOUD Nuage de points en trois dimensions.
%   P = POINTCLOUD(XYZ) range un nuage : XYZ est une matrice à trois
%   colonnes, une ligne par point, ou un tableau M×N×3 pour un nuage
%   organisé — celui que rend une caméra de profondeur, où le voisinage
%   dans l'image dit quelque chose du voisinage dans l'espace.
%
%   POINTCLOUD(...,'Color',C,'Normal',N,'Intensity',I) attache une
%   couleur, une normale et une intensité à chaque point.
%
%   Les propriétés calculées XLimits, YLimits, ZLimits et Count donnent
%   l'étendue et le nombre de points.
%
%   Exemple :
%      p = pointCloud(rand(1000, 3));
%      p.Count
%      pcdownsample(p, 'gridAverage', 0.1)
%
%   Voir aussi PCDOWNSAMPLE, PCDENOISE, PCFITPLANE, PCREGISTERICP,
%   PCTRANSFORM, PCMERGE, PCNORMALS, PCSEGDIST.
    properties
        Location = []
        Color = []
        Normal = []
        Intensity = []
    end

    properties (Dependent)
        Count
        XLimits
        YLimits
        ZLimits
    end

    methods
        function obj = pointCloud(xyz, varargin)
            if nargin == 0
                return
            end
            obj.Location = double(xyz);
            k = 1;
            while k + 1 <= numel(varargin)
                switch lower(char(varargin{k}))
                    case 'color',     obj.Color = varargin{k+1};
                    case 'normal',    obj.Normal = double(varargin{k+1});
                    case 'intensity', obj.Intensity = double(varargin{k+1});
                    otherwise
                        error('vision:pointCloud:Option', ...
                              'Propriété inconnue : %s.', char(varargin{k}));
                end
                k = k + 2;
            end
        end

        function valeur = get.Count(obj)
            valeur = size(matlibre_nuage_points(obj), 1);
        end

        function bornes = get.XLimits(obj)
            bornes = matlibre_nuage_bornes(obj, 1);
        end

        function bornes = get.YLimits(obj)
            bornes = matlibre_nuage_bornes(obj, 2);
        end

        function bornes = get.ZLimits(obj)
            bornes = matlibre_nuage_bornes(obj, 3);
        end
    end
end
