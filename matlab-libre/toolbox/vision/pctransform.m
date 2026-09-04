function nuage = pctransform(entree, transformation)
%PCTRANSFORM Applique une transformation rigide à un nuage de points.
%   Q = PCTRANSFORM(P,T) déplace le nuage. T est une matrice homogène
%   4x4, ou une matrice 3x3 de rotation, ou une structure portant les
%   champs T ou A.
%
%   La convention retenue est celle des colonnes : le point est un
%   vecteur colonne, et la transformation le multiplie à gauche. Une
%   matrice donnée dans la convention de MATLAB — translation en
%   dernière ligne — est reconnue et transposée.
%
%   Les normales, s'il y en a, subissent la seule rotation : une normale
%   ne se translate pas.
%
%   Exemple :
%      T = [eye(3), [1;2;3]; 0 0 0 1];
%      q = pctransform(pointCloud(rand(100,3)), T);
%
%   Voir aussi POINTCLOUD, PCREGISTERICP, PCMERGE.
    points = matlibre_nuage_points(entree);
    M = matlibre_transformation_rigide(transformation);
    R = M(1:3, 1:3);
    t = M(1:3, 4);
    deplaces = points * R.' + repmat(t.', size(points, 1), 1);
    nuage = matlibre_nuage_copier(entree, deplaces);
    if isa(entree, 'pointCloud') && ~isempty(entree.Normal)
        nuage.Normal = entree.Normal * R.';
    end
end
