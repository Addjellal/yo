function aire = areaint(latitudes, longitudes, rayon)
%AREAINT Aire d'un polygone sphérique, par l'excès sphérique.
    if nargin < 3
        rayon = 6371000;
    end
    lat = latitudes(:) * pi/180;
    lon = longitudes(:) * pi/180;
    n = numel(lat);
    somme = 0;
    for k = 1:n
        j = mod(k, n) + 1;
        somme = somme + (lon(j) - lon(k)) * (2 + sin(lat(k)) + sin(lat(j)));
    end
    aire = abs(somme * rayon^2 / 2);
end
