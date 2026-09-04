function vq = griddata(x, y, v, xq, yq, methode)
%GRIDDATA Interpolation de données dispersées.
%   VQ = GRIDDATA(X,Y,V,XQ,YQ) interpole les valeurs V connues aux points
%   dispersés (X,Y) et les évalue en (XQ,YQ). Les points sont d'abord
%   triangulés ; chaque point demandé est situé dans un triangle, et sa
%   valeur lue par interpolation barycentrique.
%
%   VQ = GRIDDATA(...,METHODE) où METHODE vaut :
%     'linear'   le défaut : plan par triangle, continu mais anguleux
%     'nearest'  la valeur du point de données le plus proche
%     'natural'  moyenne pondérée par la distance inverse, lissée
%     'cubic'    interpolation par plaque mince, lisse et exacte aux
%                points de données
%     'v4'       comme 'cubic'
%
%   Un point demandé hors de l'enveloppe convexe des données reçoit NaN,
%   sauf avec 'nearest' : au-delà des données, il n'y a rien à
%   interpoler, et extrapoler serait inventer.
%
%   Exemple :
%      [x, y] = meshgrid(0:0.25:1, 0:0.25:1);
%      z = 2 * x - 3 * y;
%      abs(griddata(x(:), y(:), z(:), 0.3, 0.7) - (0.6 - 2.1)) < 1e-12
%
%   Voir aussi DELAUNAY, INTERP2, INTERP1, SCATTEREDINTERPOLANT.
    if nargin < 6 || isempty(methode)
        methode = 'linear';
    end
    x = double(x(:));
    y = double(y(:));
    v = double(v(:));
    forme = size(xq);
    xq = double(xq(:));
    yq = double(yq(:));
    methode = lower(char(methode));
    switch methode
        case 'nearest'
            vq = matlibre_grille_plus_proche(x, y, v, xq, yq);
        case {'cubic', 'v4'}
            vq = matlibre_plaque_mince(x, y, v, xq, yq);
        case 'natural'
            vq = matlibre_distance_inverse(x, y, v, xq, yq);
        case 'linear'
            vq = matlibre_grille_lineaire(x, y, v, xq, yq);
        otherwise
            error('MATLAB:griddata:Methode', 'Méthode inconnue : %s.', methode);
    end
    vq = reshape(vq, forme);
end
