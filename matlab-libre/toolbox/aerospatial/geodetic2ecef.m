function [x, y, z] = geodetic2ecef(latitude, longitude, altitude)
%GEODETIC2ECEF Coordonnées géodésiques (degrés) vers repère terrestre WGS84.
    a = 6378137.0;
    f = 1 / 298.257223563;
    e2 = f * (2 - f);
    lat = latitude * pi / 180;
    lon = longitude * pi / 180;
    N = a ./ sqrt(1 - e2 * sin(lat) .^ 2);
    x = (N + altitude) .* cos(lat) .* cos(lon);
    y = (N + altitude) .* cos(lat) .* sin(lon);
    z = (N * (1 - e2) + altitude) .* sin(lat);
end
