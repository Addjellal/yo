function [Xe, Ye, Ze] = ellipsoid(xc, yc, zc, rx, ry, rz, n)
%ELLIPSOID Coordonnées d'un ellipsoïde.
%   ELLIPSOID(XC,YC,ZC,RX,RY,RZ) trace l'ellipsoïde centré en
%   (XC,YC,ZC) et de demi-axes RX, RY et RZ.
%   ELLIPSOID(...,N) emploie N mailles ; vingt par défaut.
%
%   [X,Y,Z] = ELLIPSOID(...) rend les trois grilles sans rien tracer.
%
%   L'ellipsoïde sert à représenter une covariance : les demi-axes sont
%   les racines des valeurs propres, à un facteur près qui fixe la
%   probabilité couverte.
%
%   Le rendu de MatLibre est plan, comme pour SPHERE.
%
%   Exemples :
%      ellipsoid(0, 0, 0, 3, 1, 2);
%      [X, Y, Z] = ellipsoid(1, 2, 3, 1, 1, 1, 10);
%      size(X)                          % 11 par 11
%
%   Voir aussi SPHERE, CYLINDER, SURF, MESH, COV.
    if nargin < 7 || isempty(n)
        n = 20;
    end
    [Xu, Yu, Zu] = sphere(n);
    Xe = xc + rx * Xu;
    Ye = yc + ry * Yu;
    Ze = zc + rz * Zu;
    if nargout == 0
        surf(Xe, Ye, Ze);
        clear Xe;
    end
end
