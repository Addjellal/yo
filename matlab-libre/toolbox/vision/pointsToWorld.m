function pointsMonde = pointsToWorld(parametres, rotation, translation, pointsImage)
%POINTSTOWORLD Relève des points image sur le plan z égal à zéro du monde.
%   P = POINTSTOWORLD(PARAMS,R,T,POINTS) rend les coordonnées dans le
%   monde des points image, en supposant qu'ils appartiennent au plan
%   z = 0.
%
%   Une image ne suffit pas à situer un point dans l'espace : elle donne
%   un rayon, non un point. Il faut donc une hypothèse de plus, et
%   celle-ci — le point est au sol — est la plus courante.
%
%   Exemple :
%      c = cameraIntrinsics([800 800], [320 240], [480 640]);
%      pointsToWorld(c, eye(3), [0 0 10], [320 240])    % [0 0]
%
%   Voir aussi WORLDTOIMAGE, CAMERAMATRIX, TRIANGULATE.
    K = matlibre_camera_matrice(parametres);
    R = double(rotation);
    t = double(translation(:)).';
    % Sur le plan z = 0, la projection se réduit à une homographie : la
    % troisième colonne de la rotation ne sert plus.
    H = [R(1, :); R(2, :); t] * K;
    image = double(pointsImage);
    homogenes = [image, ones(size(image, 1), 1)] / H;
    pointsMonde = homogenes(:, 1:2) ./ repmat(homogenes(:, 3), 1, 2);
end
