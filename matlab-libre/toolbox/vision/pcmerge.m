function nuage = pcmerge(premier, second, pas)
%PCMERGE Fusionne deux nuages de points.
%   Q = PCMERGE(P1,P2,PAS) réunit les deux nuages et fond en un seul
%   point ceux qui tombent dans le même cube de côté PAS.
%
%   Sans cette fusion, recoller deux relevés d'une même scène doublerait
%   la densité dans leur recouvrement, ce qui fausse tout calcul de
%   normale ou de plan.
%
%   Exemple :
%      q = pcmerge(pointCloud(rand(100,3)), pointCloud(rand(100,3)), 0.05);
%
%   Voir aussi PCDOWNSAMPLE, PCREGISTERICP, POINTCLOUD.
    if nargin < 3 || isempty(pas)
        pas = 0.01;
    end
    points = [matlibre_nuage_points(premier); matlibre_nuage_points(second)];
    fusionne = pointCloud(points);
    nuage = matlibre_nuage_grille(fusionne, points, pas);
end
