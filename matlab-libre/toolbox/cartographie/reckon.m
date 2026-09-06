function [lat2, lon2] = reckon(lat1, lon1, distance, cap, rayon)
%RECKON Point atteint en suivant un cap sur une distance donnée.
%   [LAT2,LON2] = RECKON(LAT1,LON1,DISTANCE,CAP) rend le point atteint en
%   suivant l'orthodromie de cap initial CAP, en degrés, sur DISTANCE
%   mètres. RECKON(...,RAYON) impose le rayon.
%
%   C'est la réciproque de DISTANCEGC : partir d'un point, suivre le cap
%   et la distance qu'elle donne, et retomber sur l'autre point. C'est la
%   vérification qui éprouve les deux à la fois.
%
%   Suivre le cap initial ne veut pas dire garder ce cap : l'orthodromie
%   le fait varier. Le point rendu est bien celui d'un grand cercle, non
%   d'une route à cap constant.
%
%   Exemple :
%      [lat, lon] = reckon(0, 0, 111195, 0);        % un degre vers le nord
%      [d, cap] = distanceGC(48.86, 2.35, 40.71, -74.01);
%      reckon(48.86, 2.35, d, cap)                  % retombe sur New York
%
%   Voir aussi DISTANCEGC, AREAINT, DEG2UTM.
    if nargin < 5
        rayon = 6371000;
    end
    p1 = lat1 * pi/180;
    l1 = lon1 * pi/180;
    t = cap * pi/180;
    delta = distance / rayon;
    p2 = asin(sin(p1)*cos(delta) + cos(p1)*sin(delta)*cos(t));
    l2 = l1 + atan2(sin(t)*sin(delta)*cos(p1), cos(delta) - sin(p1)*sin(p2));
    lat2 = p2 * 180/pi;
    lon2 = mod(l2 * 180/pi + 540, 360) - 180;
end
