function points = pointCloudFromRanges(distances, angles)
%POINTCLOUDFROMRANGES Nuage cartésien à partir d'un balayage polaire.
%   P = POINTCLOUDFROMRANGES(DISTANCES,ANGLES) rend un nuage à deux
%   colonnes, X et Y, à partir des distances mesurées et de l'angle de
%   chaque rayon, en radians.
%
%   Un télémètre ne rend que des distances : c'est en cartésien que la
%   géométrie redevient lisible. Un mur droit, par exemple, donne des
%   distances qui croissent en 1/cos(theta) — rien n'y ressemble à une
%   droite tant qu'on n'a pas converti.
%
%   La conversion est un simple changement de coordonnées : elle conserve
%   les distances à l'origine, et n'invente rien.
%
%   Exemple :
%      angles = deg2rad(-40:0.5:40);
%      points = pointCloudFromRanges(2 ./ cos(angles), angles);
%      max(abs(points(:,1) - 2))       % 0 : un mur droit a 2 m
%
%   Voir aussi VOXELDOWNSAMPLE, FITPLANERANSAC, ICPREGISTER.
    distances = distances(:);
    angles = angles(:);
    points = [distances .* cos(angles), distances .* sin(angles)];
end
