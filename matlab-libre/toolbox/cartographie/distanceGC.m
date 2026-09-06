function [d, cap] = distanceGC(lat1, lon1, lat2, lon2, rayon)
%DISTANCEGC Distance orthodromique et cap initial.
%   [D,CAP] = DISTANCEGC(LAT1,LON1,LAT2,LON2) rend la distance en mètres
%   le long du grand cercle, et le cap initial en degrés depuis le nord.
%   DISTANCEGC(...,RAYON) impose le rayon.
%
%   L'orthodromie est le plus court chemin sur la sphère : c'est
%   l'intersection de celle-ci avec le plan qui passe par les deux points
%   et le centre. Elle paraît courbe sur une carte de Mercator, ce qui
%   n'est pas une illusion mais une propriété de la projection.
%
%   Le cap rendu est le cap *initial* : il change tout au long du trajet,
%   sauf le long d'un méridien ou de l'équateur. Le suivre constamment
%   donnerait la loxodromie, plus longue.
%
%   Exemple :
%      [d, cap] = distanceGC(48.86, 2.35, 40.71, -74.01);   % Paris-New York
%      d / 1000                        % environ 5837 km
%      cap                             % pres de 292 degres, non 270
%
%   Voir aussi RECKON, AREAINT, DEG2UTM, HAVERSINE.
    if nargin < 5
        rayon = 6371000;
    end
    p1 = lat1 * pi/180; p2 = lat2 * pi/180;
    dl = (lon2 - lon1) * pi/180;
    a = sin((p2-p1)/2).^2 + cos(p1).*cos(p2).*sin(dl/2).^2;
    d = 2 * rayon * atan2(sqrt(a), sqrt(1-a));
    cap = mod(atan2(sin(dl).*cos(p2), cos(p1).*sin(p2) - sin(p1).*cos(p2).*cos(dl)) ...
              * 180/pi + 360, 360);
end
