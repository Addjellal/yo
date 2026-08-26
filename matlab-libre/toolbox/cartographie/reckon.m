function [lat2, lon2] = reckon(lat1, lon1, distance, cap, rayon)
%RECKON Point atteint en suivant un cap sur une distance donnée.
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
