function [nuage, indices, rejetes] = pcdenoise(entree, varargin)
%PCDENOISE Retire les points aberrants d'un nuage.
%   Q = PCDENOISE(P) écarte les points dont la distance moyenne à leurs
%   voisins s'écarte trop de la distance moyenne du nuage entier.
%
%   Un point de mesure isolé n'est pas une petite erreur : c'est un point
%   qui n'existe pas. Le filtre repose sur cette idée — un vrai point a
%   des voisins proches, un artefact n'en a pas.
%
%   PCDENOISE(...,'NumNeighbors',K) fixe le nombre de voisins (quatre),
%   'Threshold',T le nombre d'écarts types toléré (un).
%
%   [Q,I,R] = PCDENOISE(...) rend les indices gardés et rejetés.
%
%   Exemple :
%      p = pointCloud([randn(500,3); 20 * randn(5,3)]);
%      q = pcdenoise(p);
%
%   Voir aussi PCDOWNSAMPLE, POINTCLOUD, PCSEGDIST.
    voisins = 4;
    seuil = 1;
    k = 1;
    while k + 1 <= numel(varargin)
        switch lower(char(varargin{k}))
            case 'numneighbors', voisins = round(varargin{k+1});
            case 'threshold',    seuil = varargin{k+1};
            otherwise
                error('vision:pcdenoise:Option', ...
                      'Option inconnue : %s.', char(varargin{k}));
        end
        k = k + 2;
    end
    points = matlibre_nuage_points(entree);
    n = size(points, 1);
    if n <= voisins + 1
        nuage = entree;
        indices = (1:n).';
        rejetes = zeros(0, 1);
        return
    end
    distances = matlibre_distance_voisins(points, voisins);
    moyenne = mean(distances);
    ecart = std(distances);
    garde = distances <= moyenne + seuil * ecart;
    indices = find(garde);
    rejetes = find(~garde);
    nuage = matlibre_nuage_copier(entree, points(indices, :), indices);
end
