function [d, cap] = distanceGC(lat1, lon1, lat2, lon2, rayon)
%DISTANCEGC Distance orthodromique et cap initial.
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
