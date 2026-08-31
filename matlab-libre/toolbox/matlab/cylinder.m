function [Xc, Yc, Zc] = cylinder(rayon, n)
%CYLINDER Coordonnées d'un cylindre, ou d'un solide de révolution.
%   CYLINDER trace un cylindre unité de vingt mailles.
%   CYLINDER(R) engendre le solide de révolution dont le rayon suit le
%   profil R : R scalaire donne un cylindre droit, R vecteur donne un
%   cône, un tonneau, un vase — le profil est lu de bas en haut.
%   CYLINDER(R,N) emploie N mailles sur le tour.
%
%   [X,Y,Z] = CYLINDER(...) rend les trois grilles de coordonnées, sans
%   rien tracer. Z va de 0 à 1 ; on le met ensuite à l'échelle voulue.
%
%   Le rendu de MatLibre est plan : CYLINDER sans sortie montre la
%   hauteur en couleurs.
%
%   Exemples :
%      cylinder;
%      cylinder([1 0]);                 % un cone
%      cylinder(sin(linspace(0, pi, 20)) + 0.5);    % un tonneau
%      [X, Y, Z] = cylinder(2, 10);
%      size(X)                          % 2 par 11
%
%   Voir aussi SPHERE, ELLIPSOID, SURF, MESH.
    if nargin < 1 || isempty(rayon)
        rayon = [1 1];
    end
    if isscalar(rayon)
        rayon = [rayon rayon];
    end
    if nargin < 2 || isempty(n)
        n = 20;
    end
    rayon = rayon(:);
    m = numel(rayon);
    theta = linspace(0, 2 * pi, n + 1);
    Xc = rayon * cos(theta);
    Yc = rayon * sin(theta);
    Zc = linspace(0, 1, m)' * ones(1, n + 1);
    if nargout == 0
        surf(Xc, Yc, Zc);
        clear Xc;
    end
end
