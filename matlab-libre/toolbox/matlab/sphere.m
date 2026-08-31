function [Xs, Ys, Zs] = sphere(n)
%SPHERE Coordonnées d'une sphère.
%   SPHERE trace une sphère unité de vingt mailles.
%   SPHERE(N) en emploie N.
%
%   [X,Y,Z] = SPHERE(N) rend les trois grilles de coordonnées, sans rien
%   tracer. Chacune est de taille (N+1) x (N+1). C'est la forme utile :
%   on met ensuite la sphère à l'échelle et on la déplace,
%
%      [X, Y, Z] = sphere(30);
%      surf(2*X + 5, 2*Y, 2*Z);        % une sphere de rayon 2 en x = 5
%
%   Le rendu de MatLibre est plan : SPHERE sans sortie montre la
%   troisième coordonnée en couleurs, ce qui donne le disque ombré qu'on
%   verrait de face.
%
%   Exemples :
%      sphere;
%      [X, Y, Z] = sphere(10);
%      size(X)                          % 11 par 11
%      max(max(X.^2 + Y.^2 + Z.^2))     % 1 : les points sont sur la sphere
%
%   Voir aussi CYLINDER, ELLIPSOID, SURF, MESH, PEAKS.
    if nargin < 1 || isempty(n)
        n = 20;
    end
    theta = linspace(0, 2 * pi, n + 1);          % longitude
    phi = linspace(-pi / 2, pi / 2, n + 1)';     % latitude
    Xs = cos(phi) * cos(theta);
    Ys = cos(phi) * sin(theta);
    Zs = sin(phi) * ones(1, n + 1);
    if nargout == 0
        surf(Xs, Ys, Zs);
        axis('equal');
        clear Xs;
    end
end
